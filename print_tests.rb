Dir.glob('model/simulationtests/*.*').each do |f|
  if /\.osm$/.match(f) || /\.rb$/.match(f)
    filename = File.basename(f)
    puts "  def test_#{filename.gsub('.','_')}"
    puts "    result = sim_test('#{filename}')"
    puts "  end"
    puts 
  end
end