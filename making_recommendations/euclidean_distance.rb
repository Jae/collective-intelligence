class EuclideanDistance
  def self.similarity_score(first_ratings, second_ratings)
    return 0 if first_ratings.empty? or second_ratings.empty?
    euclidean_distance = [first_ratings, second_ratings].transpose.map {|x,y| (x-y) ** 2}.inject(0) {|sum, value| sum + value}
    return 1/ (1 + euclidean_distance)
  end
end

if __FILE__ == $0
  require File.dirname(__FILE__) + '/recommendations'
  require File.dirname(__FILE__) + '/movie_ratings'
  puts EuclideanDistance.similarity_score(*Recommendations.common_ratings_from('Lisa Rose', 'Gene Seymour', Movie::RATINGS))
end