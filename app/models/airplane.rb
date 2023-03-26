class Airplane < ApplicationRecord
  has_many :flights
  has_many :seats
end