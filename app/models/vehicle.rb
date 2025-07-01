class Vehicle < ApplicationRecord
  belongs_to :user
  has_many :expenses, dependent: :restrict_with_error

  # Enumerativi
  enum vehicle_category: {
    autovettura: 0,
    fuoristrada_suv: 1,
    motociclo: 2,
    ciclomotore: 3,
    autofurgone: 4,
    autocaravan: 5
  }

  enum fuel_type: {
    benzina_verde: 0,
    elettrica: 1,
    gasolio: 2,
    ibrido_benzina: 3,
    ibrido_gasolio: 4,
    ibrido_plugin_benzina: 5,
    benzina_e_gas_liquido: 6,
    benzina_e_metano: 7,
    metano_esclusivo: 8,
    altro: 9
  }

  # Validazioni
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :vehicle_category, presence: true
  validates :fuel_type, presence: true
  validates :brand, presence: true, length: { minimum: 1, maximum: 50 }
  validates :model, presence: true, length: { minimum: 1, maximum: 50 }

  # Callback per gestire un solo veicolo predefinito per utente
  before_save :ensure_single_default_vehicle

  # Scope
  scope :for_user, ->(user) { where(user: user) }
  scope :default_for_user, ->(user) { where(user: user, default: true) }

  # Metodi helper
  def display_name
    "#{name} (#{brand} #{model})"
  end

  def category_label
    case vehicle_category
    when "autovettura" then "Autovettura"
    when "fuoristrada_suv" then "Fuoristrada/SUV"
    when "motociclo" then "Motociclo"
    when "ciclomotore" then "Ciclomotore"
    when "autofurgone" then "Autofurgone"
    when "autocaravan" then "Autocaravan"
    end
  end

  def fuel_label
    case fuel_type
    when "benzina_verde" then "Benzina verde"
    when "elettrica" then "Elettrica"
    when "gasolio" then "Gasolio"
    when "ibrido_benzina" then "Ibrido-benzina"
    when "ibrido_gasolio" then "Ibrido-gasolio"
    when "ibrido_plugin_benzina" then "Ibrido plugin-benzina"
    when "benzina_e_gas_liquido" then "Benzina e gas liquido"
    when "benzina_e_metano" then "Benzina e metano"
    when "metano_esclusivo" then "Metano esclusivo"
    when "altro" then "Altro"
    end
  end

  private

  def ensure_single_default_vehicle
    return unless default? && default_changed?

    # Rimuovi il flag predefinito da tutti gli altri veicoli dell'utente
    user.vehicles.where.not(id: id).update_all(default: false)
  end
end
