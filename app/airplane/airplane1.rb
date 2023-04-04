class Airplane1
  attr_accessor :seats

  def initialize
    @seats = Array.new(7) { Array.new(34) }
  end

  def distribute_seats
    seats_1 = 1
    # Loop through each row and col
    (1..7).each do |row|
      (1..34).each do |col|
        # Check if the cell should be ignored
        if (col.between?(5, 7) || col.between?(16, 18)) ||
           (row == 4) ||
           (row == 3 && col.between?(1, 4)) ||
           (row == 5 && col.between?(1, 4))
          @seats[row - 1][col - 1] = 'x'
        else
          @seats[row - 1][col - 1] = seats_1
          seats_1 += 1
        end
      end
    end
  end
end
