class String
  def roman_to_int
    self.gsub("III", "3").gsub("II", "2").gsub("I", "1") 
  end
end