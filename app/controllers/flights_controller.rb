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
    airplane1 = Airplane1.new
    airplane1.distribute_seats
    $airplane_1 = airplane1.seats

    airplane2 = Airplane2.new
    airplane2.distribute_seats
    $airplane_2 = airplane2.seats
  end

  # function to update airplanes with passengers
  def update_airplane(airplane, boarding_passes)
    boarding_passes.each do |boarding_pass|
      # find the row and column indices of the seat in the matrix
      row = nil
      col = nil
      airplane.each_with_index do |row_data, i|
        next unless row_data.include?(boarding_pass.seat_id)
        row = i
        col = row_data.index(boarding_pass.seat_id)
        break
      end

      # Update each element with the elements of boarding_pass
      next unless row && col
      airplane[row][col] = {
        passenger_id: boarding_pass.passenger.id,
        purchase_id: boarding_pass.purchase_id,
        seat_type_id: boarding_pass.seat_type_id,
        age: boarding_pass.passenger.age,
        seat_id: boarding_pass.seat_id
      }
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
        age: boarding_pass.passenger.age,
        seat_id: boarding_pass.seat_id
      }
    end

    # Update airplanes
    case flight.airplane_id
    when 1
      update_airplane($airplane_1, boarding_passes)
    when 2
      update_airplane($airplane_2, boarding_passes)
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

  def generate_seat(airplane, seat_id, age, person, passenger_id, i, j)
    age = person.find { |p| p[:passenger_id] == passenger_id }[:age] # retrieve age from person
    if age < 18 # if passenger is a kid
      if i > 0 && airplane[i - 1][j].is_a?(Hash) && airplane[i - 1][j][:age] < 18 # if previous seat in column is a kid
        seat_id = airplane[i + 1][j] # retrieve integer from next seat in column
        airplane[i + 1][j] = # set current seat with hash of passenger_id
          person.find do |p|
            p[:passenger_id] == passenger_id
          end
        seat_id
      else # if previous seat in column is an adult (or it is the first seat in column)
        seat_id = airplane[i][j] # retrieve integer from the current seat
        airplane[i][j] = person.find { |p| p[:passenger_id] == passenger_id }
        seat_id
      end
    else # if passenger is an adult
      seat_id = airplane[i][j] # retrieve integer from the current seat
      airplane[i][j] = # set current seat with hash of passenger_id
        person.find do |p|
          p[:passenger_id] == passenger_id
        end
      seat_id
    end
  end

  def retrieve_seat(seat_id, seat_type_id, flight, age, person, passenger_id)
    return seat_id if seat_id.present?

    case flight.airplane_id
    when 1
      airplane = $airplane_1
      case seat_type_id
      when 1 # Generate seat for premium class
        rows = $airplane_1.length
        columns = $airplane_1[0].length

        catch :found_integer do
          for j in 0...columns # iterate over columns
            for i in 0...rows # iterate over rows
              next unless $airplane_1[i][j].is_a?(Integer) # if it's an integer
              seat_id = generate_seat(airplane, seat_id, age, person, passenger_id, i, j)
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
              seat_id = generate_seat($airplane_1, seat_id, age, person, passenger_id, i, j)
              throw :found_integer # exit both loops
            end
          end
        end
        seat_id
      when 3
        rows = $airplane_1.length
        columns = $airplane_1[0].length

        catch :found_integer do
          for j in 18...columns # iterate over columns
            for i in 0...rows # iterate over rows
              next unless $airplane_1[i][j].is_a?(Integer) # if it's an integer
              seat_id = generate_seat($airplane_1, seat_id, age, person, passenger_id, i, j)
              throw :found_integer # exit both loops
            end
          end
        end
        seat_id
      end

    when 2 # Airplane 2
      airplane = $airplane_2
      case seat_type_id
      when 1 # Generate seat for premium class
        rows = $airplane_2.length
        columns = $airplane_2[0].length

        catch :found_integer do
          for j in 0...columns # iterate over columns
            for i in 0...rows # iterate over rows
              next unless $airplane_2[i][j].is_a?(Integer) # if it's an integer
              seat_id = generate_seat($airplane_2, seat_id, age, person, passenger_id, i, j)
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
              seat_id = generate_seat($airplane_2, seat_id, age, person, passenger_id, i, j)
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
              seat_id = generate_seat($airplane_2, seat_id, age, person, passenger_id, i, j)
              throw :found_integer # exit both loops
            end
          end
        end
        seat_id
      end
    end
  end
end
