# frozen_string_literal: true

# Seat generator class
class FlightsController < ApplicationController
  before_action :reset_airplanes

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

  def reset_airplanes
    airplane1 = Airplane1.new
    airplane1.distribute_seats
    @airplane1 = airplane1.seats

    airplane2 = Airplane2.new
    airplane2.distribute_seats
    @airplane2 = airplane2.seats
  end

  def passengers
    flight = Flight.find(params[:id])
    boarding_passes = BoardingPass.includes(:passenger) # if includes is removed, will cause multiple queries
                                  .joins(:passenger)
                                  .where(flight_id: flight.flight_id)
                                  .select(
                                    'passenger.passenger_id,
                                     passenger.dni,
                                     passenger.name,
                                     passenger.age,
                                     passenger.country,
                                     boarding_pass.boarding_pass_id,
                                     boarding_pass.purchase_id,
                                     boarding_pass.seat_type_id,
                                     boarding_pass.seat_id'
                                  )
                                  .references(:passengers)
                                  .order('purchase_id DESC, age')

    # Create a hash person and import the data
    person = boarding_passes.map do |boarding_pass|
      {
        passenger_id: boarding_pass.passenger.id,
        age: boarding_pass.passenger.age,
        seat_id: boarding_pass.seat_id
      }
    end

    # Update airplanes with already asigned seats
    case flight.airplane_id
    when 1
      update_airplane(@airplane1, boarding_passes)
    when 2
      update_airplane(@airplane2, boarding_passes)
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

  # Update airplanes with passengers
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

  def retrieve_seat(seat_id, seat_type_id, flight, age, person, passenger_id)
    return seat_id if seat_id.present?

    case flight.airplane_id
    when 1
      airplane = @airplane1
      # Set the seat type range
      seat_type_range = {
        1 => (0..3),
        2 => (7..14),
        3 => (18..33)
      }
    when 2
      airplane = @airplane2
      seat_type_range = {
        1 => (0..4),
        2 => (8..13),
        3 => (17..30)
      }
    end

    rows = airplane.length
    cols = seat_type_range[seat_type_id]

    catch :found_integer do
      cols.each do |j| # iterate over columns
        (0...rows).each do |i| # iterate over rows
          next unless airplane[i][j].is_a?(Integer)

          seat_id = generate_seat(airplane, seat_id, age, person, passenger_id, i, j)
          throw :found_integer # exit both loops
        end
      end
    end

    seat_id
  end

  def generate_seat(airplane, seat_id, age, person, passenger_id, i, j)
    # retrieve age
    age = person.find { |p| p[:passenger_id] == passenger_id }[:age]

    if age < 18
      # if previous seat in column is a kid
      if i > 0 && airplane[i - 1][j].is_a?(Hash) && airplane[i - 1][j][:age] < 18
        find_next_seat(airplane, i, j, person, passenger_id)
      else
        # if previous seat in column is an adult or the first seat in column
        seat_id = airplane[i][j]
        airplane[i][j] = person.find { |p| p[:passenger_id] == passenger_id }
        seat_id
      end
    else
      # if is an adult, retrieve seat and replace the integer
      seat_id = airplane[i][j]
      airplane[i][j] =
        person.find do |p|
          p[:passenger_id] == passenger_id
        end
      seat_id
    end
  end

  # Ensure that the next seat is available
  def find_next_seat(airplane, start_row, start_col, person, passenger_id)
    row_index = start_row + 1
    col_index = start_col

    while row_index < airplane.length
      if airplane[row_index][col_index].is_a?(Integer)

        # retrieve seat number and replace it with person hash
        seat_id = airplane[row_index][col_index]

        airplane[row_index][col_index] =
          person.find do |p|
            p[:passenger_id] == passenger_id
          end
        return seat_id
      end

      row_index += 1

      if row_index == airplane.length && col_index < airplane[0].length - 1
        row_index = 0
        col_index += 1
      end
    end
  end
end
