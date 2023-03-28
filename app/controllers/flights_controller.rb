class FlightsController < ApplicationController
  def passengers
    flight = Flight.find(params[:id])
    passengers = flight.boarding_passes.map do |bp|
      {
        passengerId: bp.passenger_id,
        dni: bp.passenger.dni,
        name: bp.passenger.name,
        age: bp.passenger.age,
        country: bp.passenger.country,
        boardingPassId: bp.boarding_pass_id,
        purchaseId: bp.purchase_id,
        seatTypeId: bp.seat_type_id,
        seatId: generate_seat(bp.seat_type, flight)
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
        passengers: passengers
      }
    }
  end

  private

  def generate_seat(seat_type, flight)
    taken_seats = flight.boarding_passes.pluck(:seat_id).compact.uniq
    available_seats = case flight.airplane_id
                      when 1
                        case seat_type.seat_type_id
                        when 1
                          %w[A B F G].product([1, 2, 3, 4])
                        when 2
                          %w[A B C G F E].product((8..15).to_a)
                        when 3
                          %w[A B C G F E].product((19..34).to_a)
                        end
                      when 2
                        case seat_type.seat_type_id
                        when 1
                          %w[I E A].product([1, 2, 3, 4, 5])
                        when 2
                          %w[I H F E D B A].product((9..14).to_a)
                        when 3
                          %w[I H F E D B A].product((18..31).to_a)
                        end
                      end
    available_seats.reject! do |seat_row, seat_column|
      taken_seats.include?("#{flight.flight_id}-#{seat_type.seat_type_id}-#{seat_row}#{seat_column}")
    end
    seat_row, seat_column = available_seats.first
    seat_id = case flight.airplane_id
              when 1
                case seat_type.seat_type_id
                when 1
                  (seat_row.ord - 64) * 4 + seat_column
                when 2
                  (seat_row.ord - 64) * 8 + seat_column - 7
                when 3
                  (seat_row.ord - 64) * 16 + seat_column - 18
                end
              when 2
                case seat_type.seat_type_id
                when 1
                  (seat_row.ord - 72) * 5 + seat_column
                when 2
                  (seat_row.ord - 72) * 6 + seat_column - 5 + 160
                when 3
                  (seat_row.ord - 72) * 14 + seat_column - 17 + 245
                end
              end
    "#{seat_id}-#{seat_row}#{seat_column}"
  end
end