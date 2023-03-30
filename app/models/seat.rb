class Seat < ApplicationRecord
  belongs_to :seat_type
  belongs_to :airplane
  has_one :boarding_pass
end