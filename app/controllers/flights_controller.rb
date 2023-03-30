class FlightsController < ApplicationController
  before_action :reset_global_variable

  def reset_global_variable
    # Airplane 1 matrix seat distribution
    $airplane_1 = Array.new(7) { Array.new(34) }
    seats_1 = 1
    # Loop through each row and col
    ('A'..'G').each do |row|
      (1..34).each do |col|
        # Check if the cell should be ignored
        if (col.between?(5, 7) || col.between?(16, 18)) ||
           (row == 'D') ||
           (row == 'C' && col.between?(1, 4)) ||
           (row == 'E' && col.between?(1, 4))
          $airplane_1[row.ord - 'A'.ord][col - 1] = nil
        else
          $airplane_1[row.ord - 'A'.ord][col - 1] = seats_1
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
          $airplane_2[row.ord - 'A'.ord][col - 1] = nil
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
                                  .select('boarding_pass.*, passenger.*')
                                  .references(:passengers)
                                  .order('seat_id DESC')

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
        seatId: retrieve_seat(bp.seat_id, bp.seat_type_id, flight, bp.passenger_id)
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

  def retrieve_seat(seat_id, seat_type_id, flight, _passenger_id)
    if !seat_id.nil?
      # Take occupied seat out from the planes
      case flight.airplane_id
      when 1
        ('A'..'G').each do |row|
          (1..34).each do |col|
            if $airplane_1[row.ord - 'A'.ord][col - 1] == seat_id
              # If a match is found, set the cell value to nil
              $airplane_1[row.ord - 'A'.ord][col - 1] = nil
            end
          end
        end
      when 2
        ('A'..'I').each do |row|
          (1..31).each do |col|
            if $airplane_2[row.ord - 'A'.ord][col - 1] == seat_id
              # If a match is found, set the cell value to nil
              $airplane_2[row.ord - 'A'.ord][col - 1] = nil
            end
          end
        end
      end

      seat_id
    else
      # Confirm that matrix seat removal is working
      # $airplane_1.each do |row|
      #   puts row.join("\t")
      # end

      case flight.airplane_id # Generate seats
      when 1 # Airplane 1
        case seat_type_id
        when 1 # For premium class
          while seat_id.nil?
            row = ('A'..'G').to_a.sample
            col = (1..4).to_a.sample
            value = $airplane_1[row.ord - 'A'.ord][col - 1] # Check if contains non null value
            seat_id = value unless value.nil?
            $airplane_1[row.ord - 'A'.ord][col - 1] = nil # Eliminate the seat from the matrix
          end
          seat_id
        when 2 # For medium class
          while seat_id.nil?
            row = ('A'..'G').to_a.sample
            col = (8..15).to_a.sample
            value = $airplane_1[row.ord - 'A'.ord][col - 1]
            seat_id = value unless value.nil?
            $airplane_1[row.ord - 'A'.ord][col - 1] = nil
          end
          seat_id
        when 3 # For económico
          while seat_id.nil?
            row = ('A'..'G').to_a.sample
            col = (19..34).to_a.sample
            value = $airplane_1[row.ord - 'A'.ord][col - 1]
            seat_id = value unless value.nil?
            $airplane_1[row.ord - 'A'.ord][col - 1] = nil
          end
          seat_id
        end
      when 2 # Airplane 2
        case seat_type_id
        when 1 # For premium class
          while seat_id.nil?
            row = ('A'..'I').to_a.sample
            col = (1..5).to_a.sample
            value = $airplane_2[row.ord - 'A'.ord][col - 1] # Check if contains non null value
            seat_id = value unless value.nil?
            $airplane_2[row.ord - 'A'.ord][col - 1] = nil # Eliminate the seat from the matrix
          end
          seat_id
        when 2 # For medium class
          while seat_id.nil?
            row = ('A'..'I').to_a.sample
            col = (9..14).to_a.sample
            value = $airplane_2[row.ord - 'A'.ord][col - 1]
            seat_id = value unless value.nil?
            $airplane_2[row.ord - 'A'.ord][col - 1] = nil
          end
          seat_id
        when 3 # For económico
          while seat_id.nil?
            row = ('A'..'I').to_a.sample
            col = (18..31).to_a.sample
            value = $airplane_2[row.ord - 'A'.ord][col - 1]
            seat_id = value unless value.nil?
            $airplane_2[row.ord - 'A'.ord][col - 1] = nil
          end
          seat_id
        end
      end
    end
  end
end
