class FlightsController < ApplicationController
  before_action :reset_global_variable

  rescue_from ActiveRecord::DatabaseConnectionError do |_e|
    render json: {
      code: 400,
      errors: 'could not connect to db'
    }
  end

  rescue_from ActiveRecord::RecordNotFound do |_e|
    render json: {
      "code": 404,
      "data": {}
    }
  end

  def reset_global_variable
    # Airplane 1 matrix seat distribution
    $airplane_1 = Array.new(7) { Array.new(34) }
    seats_1 = 1
    # Loop through each row and col
    (1..7).each do |row|
      (1..34).each do |col|
        # Check if the cell should be ignored
        if (col.between?(5, 7) || col.between?(16, 18)) ||
           (row == 4) ||
           (row == 3 && col.between?(1, 4)) ||
           (row == 5 && col.between?(1, 4))
          $airplane_1[row - 1][col - 1] = 'x'
        else
          $airplane_1[row - 1][col - 1] = seats_1
          seats_1 += 1
        end
      end
    end

    # Airplane 2 matrix seat distribution
    $airplane_2 = Array.new(9) { Array.new(31) }
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
          $airplane_2[row.ord - 'A'.ord][col - 1] = 'x'
        else
          $airplane_2[row.ord - 'A'.ord][col - 1] = seats_2
          seats_2 += 1
        end
      end
    end
  end

  def passengers
    flight = Flight.find(params[:id])
    boarding_passes = BoardingPass.includes(:passenger)
                                  .joins(:passenger)
                                  .where(flight_id: flight.flight_id)
                                  .select('passenger.passenger_id, passenger.dni, passenger.name, passenger.age, passenger.country,
      boarding_pass.boarding_pass_id, boarding_pass.purchase_id, boarding_pass.seat_type_id, boarding_pass.seat_id')
                                  .references(:passengers)
                                  .order('purchase_id DESC, seat_id ASC, age')

    # Create a hash and import the data
    person = boarding_passes.map do |boarding_pass|
      {
        passenger_id: boarding_pass.passenger.id,
        purchase_id: boarding_pass.purchase_id,
        seat_type_id: boarding_pass.seat_type_id,
        age: boarding_pass.passenger.age,
        seat_id: boarding_pass.seat_id
      }
    end

    # Update airplanes
    case flight.airplane_id
    when 1
      boarding_passes.each do |boarding_pass|
        # find the row and column indices of the seat in the matrix
        row = nil
        col = nil
        $airplane_1.each_with_index do |row_data, i|
          next unless row_data.include?(boarding_pass.seat_id)

          row = i
          col = row_data.index(boarding_pass.seat_id)
          break
        end

        # Update each element with the elements of boarding_pass
        next unless row && col

        $airplane_1[row][col] = {
          passenger_id: boarding_pass.passenger.id,
          purchase_id: boarding_pass.purchase_id,
          seat_type_id: boarding_pass.seat_type_id,
          age: boarding_pass.passenger.age,
          seat_id: boarding_pass.seat_id
        }
      end
    when 2
      # put your code here
      boarding_passes.each do |boarding_pass|
        # find the row and column indices of the seat in the matrix
        row = nil
        col = nil
        $airplane_2.each_with_index do |row_data, i|
          next unless row_data.include?(boarding_pass.seat_id)

          row = i
          col = row_data.index(boarding_pass.seat_id)
          break
        end

        next unless row && col

        $airplane_2[row][col] = {
          passenger_id: boarding_pass.passenger.id,
          purchase_id: boarding_pass.purchase_id,
          seat_type_id: boarding_pass.seat_type_id,
          age: boarding_pass.passenger.age,
          seat_id: boarding_pass.seat_id
        }
      end
    end

    passengers = boarding_passes.map do |bp|
      {
        passengerId: bp.passenger_id,
        dni: bp.passenger.dni,
        name: bp.passenger.name,
        age: bp.passenger.age,
        country: bp.passenger.country,
        boardingPassId: bp.boarding_pass_id,
        purchaseId: bp.purchase_id,
        seatTypeId: bp.seat_type_id,
        seatId: retrieve_seat(bp.seat_id, bp.seat_type_id, flight, bp.age, person, bp.passenger_id)
      }
    end

    render json: {
      code: 200,
      data: {
        flightId: flight.flight_id,
        takeoffDateTime: flight.takeoff_date_time,
        takeoffAirport: flight.takeoff_airport,
        landingDateTime: flight.landing_date_time,
        landingAirport: flight.landing_airport,
        airplaneId: flight.airplane_id,
        passengers:
      }
    }
  end

  def retrieve_seat(seat_id, seat_type_id, flight, age, person, passenger_id)
    return seat_id if seat_id.present?

    case flight.airplane_id
    when 1
      case seat_type_id
      when 1 # Generate seat for premium class
        rows = $airplane_1.length
        columns = $airplane_1[0].length

        catch :found_integer do
          for j in 0...columns # iterate over columns
            for i in 0...rows # iterate over rows
              next unless $airplane_1[i][j].is_a?(Integer) # if it's an integer

              age = person.find { |p| p[:passenger_id] == passenger_id }[:age] # retrieve age from person
              if age < 18 # if passenger is a kid
                if i > 0 && $airplane_1[i - 1][j].is_a?(Hash) && $airplane_1[i - 1][j][:age] < 18 # if previous seat in column is a kid
                  seat_id = $airplane_1[i + 1][j] # retrieve integer from next seat in column
                  $airplane_1[i + 1][j] = # set current seat with hash of passenger_id
                    person.find do |p|
                      p[:passenger_id] == passenger_id
                    end
                else # if previous seat in column is an adult (or it is the first seat in column)
                  seat_id = $airplane_1[i][j] # retrieve integer from the current seat
                  $airplane_1[i][j] = person.find { |p| p[:passenger_id] == passenger_id }
                end
              else # if passenger is an adult
                seat_id = $airplane_1[i][j] # retrieve integer from the current seat
                $airplane_1[i][j] = # set current seat with hash of passenger_id
                  person.find do |p|
                    p[:passenger_id] == passenger_id
                  end
              end
              # print "#{$airplane_1[i][j]} "
              throw :found_integer # exit both loops
            end
          end
        end
        seat_id
      when 2
        rows = $airplane_1.length
        columns = $airplane_1[0].length

        catch :found_integer do
          for j in 7...columns # iterate over columns
            for i in 0...rows # iterate over rows
              next unless $airplane_1[i][j].is_a?(Integer) # if it's an integer

              age = person.find { |p| p[:passenger_id] == passenger_id }[:age] # retrieve age from person
              if age < 18 # if passenger is a kid
                if i > 0 && $airplane_1[i - 1][j].is_a?(Hash) && $airplane_1[i - 1][j][:age] < 18 # if previous seat in column is a kid
                  seat_id = $airplane_1[i + 1][j] # retrieve integer from next seat in column
                  $airplane_1[i + 1][j] = # set current seat with hash of passenger_id
                    person.find do |p|
                      p[:passenger_id] == passenger_id
                    end
                else # if previous seat in column is an adult (or it is the first seat in column)
                  seat_id = $airplane_1[i][j] # retrieve integer from the current seat
                  $airplane_1[i][j] = person.find { |p| p[:passenger_id] == passenger_id }
                end
              else # if passenger is an adult
                seat_id = $airplane_1[i][j] # retrieve integer from the current seat
                $airplane_1[i][j] = # set current seat with hash of passenger_id
                  person.find do |p|
                    p[:passenger_id] == passenger_id
                  end
              end
              # print "#{$airplane_1[i][j]} "
              throw :found_integer # exit both loops
            end
          end
        end
        seat_id
      when 3
        # check if airplane updates with person data
        # $airplane_1.each { |row| puts row.join(' ') }
        rows = $airplane_1.length
        columns = $airplane_1[0].length

        catch :found_integer do
          for j in 18...columns # iterate over columns
            for i in 0...rows # iterate over rows
              next unless $airplane_1[i][j].is_a?(Integer) # if it's an integer

              age = person.find { |p| p[:passenger_id] == passenger_id }[:age] # retrieve age from person
              if age < 18 # if passenger is a kid
                if i > 0 && $airplane_1[i - 1][j].is_a?(Hash) && $airplane_1[i - 1][j][:age] < 18 # if previous seat in column is a kid
                  seat_id = $airplane_1[i + 1][j] # retrieve integer from next seat in column
                  $airplane_1[i + 1][j] = # set current seat with hash of passenger_id
                    person.find do |p|
                      p[:passenger_id] == passenger_id
                    end
                else # if previous seat in column is an adult (or it is the first seat in column)
                  seat_id = $airplane_1[i][j] # retrieve integer from the current seat
                  $airplane_1[i][j] = person.find { |p| p[:passenger_id] == passenger_id }
                end
              else # if passenger is an adult
                seat_id = $airplane_1[i][j] # retrieve integer from the current seat
                $airplane_1[i][j] = # set current seat with hash of passenger_id
                  person.find do |p|
                    p[:passenger_id] == passenger_id
                  end
              end
              # print "#{$airplane_1[i][j]} "
              throw :found_integer # exit both loops
            end
          end
        end
        seat_id
      end

    when 2 # Airplane 2
      case seat_type_id
      when 1 # Generate seat for premium class
        rows = $airplane_2.length
        columns = $airplane_2[0].length

        catch :found_integer do
          for j in 0...columns # iterate over columns
            for i in 0...rows # iterate over rows
              next unless $airplane_2[i][j].is_a?(Integer) # if it's an integer

              age = person.find { |p| p[:passenger_id] == passenger_id }[:age] # retrieve age from person
              if age < 18 # if passenger is a kid
                if i > 0 && $airplane_2[i - 1][j].is_a?(Hash) && $airplane_2[i - 1][j][:age] < 18 # if previous seat in column is a kid
                  seat_id = $airplane_2[i + 1][j] # retrieve integer from next seat in column
                  $airplane_2[i + 1][j] = # set current seat with hash of passenger_id
                    person.find do |p|
                      p[:passenger_id] == passenger_id
                    end
                else # if previous seat in column is an adult (or it is the first seat in column)
                  seat_id = $airplane_2[i][j] # retrieve integer from the current seat
                  $airplane_2[i][j] = person.find { |p| p[:passenger_id] == passenger_id }
                end
              else # if passenger is an adult
                seat_id = $airplane_2[i][j] # retrieve integer from the current seat
                $airplane_2[i][j] = # set current seat with hash of passenger_id
                  person.find do |p|
                    p[:passenger_id] == passenger_id
                  end
              end
              # print "#{$airplane_1[i][j]} "
              throw :found_integer # exit both loops
            end
          end
        end
        seat_id
      when 2
        rows = $airplane_2.length
        columns = $airplane_2[0].length

        catch :found_integer do
          for j in 8...columns # iterate over columns
            for i in 0...rows # iterate over rows
              next unless $airplane_2[i][j].is_a?(Integer) # if it's an integer

              age = person.find { |p| p[:passenger_id] == passenger_id }[:age] # retrieve age from person
              if age < 18 # if passenger is a kid
                if i > 0 && $airplane_2[i - 1][j].is_a?(Hash) && $airplane_2[i - 1][j][:age] < 18 # if previous seat in column is a kid
                  seat_id = $airplane_2[i + 1][j] # retrieve integer from next seat in column
                  $airplane_2[i + 1][j] = # set current seat with hash of passenger_id
                    person.find do |p|
                      p[:passenger_id] == passenger_id
                    end
                else # if previous seat in column is an adult (or it is the first seat in column)
                  seat_id = $airplane_2[i][j] # retrieve integer from the current seat
                  $airplane_2[i][j] = person.find { |p| p[:passenger_id] == passenger_id }
                end
              else # if passenger is an adult
                seat_id = $airplane_2[i][j] # retrieve integer from the current seat
                $airplane_2[i][j] = # set current seat with hash of passenger_id
                  person.find do |p|
                    p[:passenger_id] == passenger_id
                  end
              end
              # print "#{$airplane_1[i][j]} "
              throw :found_integer # exit both loops
            end
          end
        end
        seat_id
      when 3
        # check if airplane updates with person data
        # $airplane_1.each { |row| puts row.join(' ') }
        rows = $airplane_2.length
        columns = $airplane_2[0].length

        catch :found_integer do
          for j in 17...columns # iterate over columns
            for i in 0...rows # iterate over rows
              next unless $airplane_2[i][j].is_a?(Integer) # if it's an integer

              age = person.find { |p| p[:passenger_id] == passenger_id }[:age] # retrieve age from person
              if age < 18 # if passenger is a kid
                if i > 0 && $airplane_2[i - 1][j].is_a?(Hash) && $airplane_2[i - 1][j][:age] < 18 # if previous seat in column is a kid
                  seat_id = $airplane_2[i + 1][j] # retrieve integer from next seat in column
                  $airplane_2[i + 1][j] = # set current seat with hash of passenger_id
                    person.find do |p|
                      p[:passenger_id] == passenger_id
                    end
                else # if previous seat in column is an adult (or it is the first seat in column)
                  seat_id = $airplane_2[i][j] # retrieve integer from the current seat
                  $airplane_2[i][j] = person.find { |p| p[:passenger_id] == passenger_id }
                end
              else # if passenger is an adult
                seat_id = $airplane_2[i][j] # retrieve integer from the current seat
                $airplane_2[i][j] = # set current seat with hash of passenger_id
                  person.find do |p|
                    p[:passenger_id] == passenger_id
                  end
              end
              # print "#{$airplane_1[i][j]} "
              throw :found_integer # exit both loops
            end
          end
        end
        seat_id
      end
    end
  end
end
