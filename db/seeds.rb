# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Creazione progetti di esempio
puts "Creazione progetti di esempio..."

projects_data = [
  { name: "CP.01 itWikiCon - Dario", budget: 15000.00, active: true },
  { name: "CP.02 Foss4Git-OSMit - Anisa", budget: 8000.00, active: true },
  { name: "CP.03 Wikimania - Dario", budget: 20000.00, active: true },
  { name: "CP.04 State of the Map - Anisa", budget: 12000.00, active: true },
  { name: "CP.05 Finanziamento progetti volontari - Anisa", budget: 25000.00, active: true },
  { name: "CP.06 Fondo microgrant - Dario", budget: 5000.00, active: true },
  { name: "CP.07 Fondo coordinatori - Anisa", budget: 10000.00, active: true },
  { name: "CP.08 Incontro coordinatori - Anisa", budget: 7000.00, active: true },
  { name: "ST.24 Rimborsi spesa soci/staff/direttivo - Direttore esecutivo", budget: 30000.00, active: true },
  { name: "Altro", budget: 5000.00, active: true }
]

projects_data.each do |project_attrs|
  project = Project.find_or_initialize_by(name: project_attrs[:name])
  project.update!(project_attrs)
  puts "✓ Progetto creato: #{project.name}"
end

puts "#{Project.count} progetti totali nel database."
