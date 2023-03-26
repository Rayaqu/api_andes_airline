class BoardingPass < ApplicationRecord
  belongs_to :purchase
  belongs_to :passenger
  belongs_to :seat_type
  belongs_to :seat, optional: true
  belongs_to :flight
end