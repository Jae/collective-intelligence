class TanimotoScore
  def self.similarity_score(first_ratings, second_ratings)
    fail_if_nonbinary_values(first_ratings);fail_if_nonbinary_values(second_ratings)
    
    return 0.0 if first_ratings.empty? or second_ratings.empty?
    intersections = [first_ratings, second_ratings].transpose.reduce(0.0) {|intersections, ratings| intersections + logical_and(*ratings)}
    unions = [first_ratings, second_ratings].transpose.reduce(0.0) {|unions, ratings| unions + logical_or(*ratings)}
    return 0 if unions == 0
    intersections / unions
  end
  
  private
  def self.fail_if_nonbinary_values(ratings)
    raise "TanimotoScore doesn't support nonbinary values in #{ratings}" unless ratings.reject{|e| [0,1].include? e}.empty?
  end
  
  def self.logical_and(att1, att2)
    (att1 == 1) && (att2 == 1) ? 1 : 0
  end
  
  def self.logical_or(att1, att2)
    (att1 == 1) || (att2 == 1) ? 1 : 0
  end
end

if __FILE__ == $0
  puts TanimotoScore.similarity_score([0,1,0], [1,0,1])
end