require 'securerandom' # To generate random positions for the collectible

class Grid
  attr_reader :width, :height, :obstacles, :collectible

  def initialize(width, height)
    @width = width
    @height = height
    @obstacles = []
    @collectible = spawn_collectible

    # Define walls and obstacles
    add_wall(3, 8, 5, 8)
    add_wall(6, 8, 8, 8)
    add_wall(2, 10, 4, 10)
    add_obstacle(4, 6)
    add_obstacle(5, 12)
  end

  def add_wall(x1, y1, x2, y2)
    if x1 == x2
      (y1..y2).each { |y| @obstacles << [x1, y] }
    elsif y1 == y2
      (x1..x2).each { |x| @obstacles << [x, y1] }
    end
  end

  def add_obstacle(x, y)
    @obstacles << [x, y]
  end

  def has_obstacle?(x, y)
    @obstacles.include?([x, y])
  end

  def within_bounds?(x, y)
    x.between?(1, @width) && y.between?(1, @height)
  end

  def spawn_collectible
    # Generate random positions until we find one that is within bounds and not on an obstacle
    loop do
      random_x = SecureRandom.random_number(1..@width)
      random_y = SecureRandom.random_number(1..@height)
      return [random_x, random_y] unless has_obstacle?(random_x, random_y)
    end
  end

  def display(car, score)
    direction_symbol = { 'U' => '^', 'R' => '>', 'D' => 'V', 'L' => '<' }[car.direction]
    puts "\n" + "--" + " Score: #{score} " + "--"
    puts "\n"
    (1..@height).reverse_each do |y|
      line = ""
      (1..@width).each do |x|
        if [car.x, car.y] == [x, y]
          line += direction_symbol # Car's current position with direction
        elsif [x, y] == @collectible
          line += 'O' # Collectible
        elsif has_obstacle?(x, y)
          line += 'X' # Obstacle or wall
        else
          line += '.' # Empty space
        end
      end
      puts line
    end
    puts "\n"
  end

  def collectible_reached?(car)
    [car.x, car.y] == @collectible
  end

  def reset_collectible
    @collectible = spawn_collectible
  end
end

class Car
  DIRECTIONS = ['U', 'R', 'D', 'L'] # Up, Right, Down, Left

  attr_reader :x, :y, :direction, :grid

  def initialize(grid, x = 5, y = 5, direction = 'U')
    @grid = grid
    @x = x
    @y = y
    @direction = direction
  end

  def turn_left
    current_index = DIRECTIONS.index(@direction)
    @direction = DIRECTIONS[(current_index - 1) % 4]
  end

  def turn_right
    current_index = DIRECTIONS.index(@direction)
    @direction = DIRECTIONS[(current_index + 1) % 4]
  end

  def move_forward(n)
    n.times do
      new_x, new_y = next_position(1)
      if can_move_to?(new_x, new_y)
        @x, @y = new_x, new_y
        return position_output if @grid.collectible_reached?(self)
      else
        return collision_output
      end
    end
    position_output
  end

  def move_backward(n)
    n.times do
      new_x, new_y = next_position(-1)
      if can_move_to?(new_x, new_y)
        @x, @y = new_x, new_y
        return position_output if @grid.collectible_reached?(self)
      else
        return collision_output
      end
    end
    position_output
  end

  def next_position(step)
    case @direction
    when 'U' then [@x, @y + step]
    when 'R' then [@x + step, @y]
    when 'D' then [@x, @y - step]
    when 'L' then [@x - step, @y]
    end
  end

  def can_move_to?(x, y)
    @grid.within_bounds?(x, y) && !@grid.has_obstacle?(x, y)
  end

  def position_output
    "(#{@x},#{@y},#{@direction})"
  end

  def collision_output
    "(#{@x},#{@y},#{@direction})*"
  end
end

def process_instructions
  grid = Grid.new(15, 10)
  car = Car.new(grid)
  score = 0

  # Display the grid before accepting input
  grid.display(car, score)

  loop do
    puts "Enter instructions (e.g., 'F2, L, B1, R, F3') or type 'exit' to quit:"
    input = gets.chomp
    break if input.downcase == 'exit'

    outputs = []

    input.split(',').each do |instruction|
      instruction = instruction.strip
      case instruction
      when /^F(\d+)$/
        result = car.move_forward($1.to_i)
        outputs << result
      when /^B(\d+)$/
        result = car.move_backward($1.to_i)
        outputs << result
      when 'L'
        car.turn_left
        outputs << car.position_output
      when 'R'
        car.turn_right
        outputs << car.position_output
      else
        outputs << "Invalid instruction: #{instruction}"
      end

      # Check if collectible is reached and update score
      if grid.collectible_reached?(car)
        score += 1
        grid.reset_collectible
        puts "You collected an item! New score: #{score}"
      end

      grid.display(car, score) # Update the grid display after each instruction
    end

    puts outputs.join(', ')
  end
end

# Run the program
process_instructions
