class Airplane2
  attr_accessor :seats

  def initialize
    @seats = Array.new(9) { Array.new(31) }
  end

  def distribute_seats
    seats_2 = 161
    # Loop through each row and col
    ('A'..'I').each do |row|
      (1..31).each do |col|
        # Check if the cell should be ignored
        if (col.between?(6, 8) || col.between?(15, 17)) ||
           (row == 'C') ||
           (row == 'G') ||
           (row == 'B' && col.between?(1, 5)) ||
           (row == 'D' && col.between?(1, 5)) ||
           (row == 'F' && col.between?(1, 5)) ||
           (row == 'H' && col.between?(1, 5))
          @seats[row.ord - 'A'.ord][col - 1] = 'x'
        else
          @seats[row.ord - 'A'.ord][col - 1] = seats_2
          seats_2 += 1
        end
      end
    end
  end
end
