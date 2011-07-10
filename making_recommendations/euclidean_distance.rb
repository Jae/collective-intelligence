require File.dirname(__FILE__) + '/recommendations'

class EuclideanDistance
  def self.similarity_score(first_ratings, second_ratings)
    return 0 if first_ratings.empty? or second_ratings.empty?
    
    return 1/ (1 + [first_ratings, second_ratings].transpose.map {|x,y| (x-y) ** 2}.inject(0) {|sum, value| sum + value})
  end
end

if __FILE__ == $0
  puts EuclideanDistance.similarity_score(*movie_ratings_from('Lisa Rose', 'Gene Seymour'))
end