class FlightsController < ApplicationController
  def passengers
    flight = Flight.find(params[:id])

    if flight.nil?
      render json: { code: 404, data: {} }
      return
    end

    # Implementar algoritmo de asignación de asientos aquí

    # Transformar datos a Camel case y construir respuesta
    response_data = {
      flightId: flight.id,
      takeoffDateTime: flight.takeoff_date_time,
      takeoffAirport: flight.takeoff_airport,
      landingDateTime: flight.landing_date_time,
      landingAirport: flight.landing_airport,
      airplaneId: flight.airplane_id,
      # passengers: passengers_data # Variable que contiene datos de los pasajeros después de asignar asientos
    }

    render json: { code: 200, data: response_data }
  # rescue => e
  #   render json: { code: 400, errors: 'could not connect to db' }
  end
end