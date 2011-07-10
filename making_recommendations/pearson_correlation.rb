require File.dirname(__FILE__) + '/recommendations'

class PearsonCorrelation
  def self.similarity_score(first_ratings, second_ratings)
    return 0 if first_ratings.empty? or second_ratings.empty?
    return covariance(first_ratings, second_ratings) / sd(first_ratings) / sd(second_ratings)
  end
    
  private
  def self.mean(values)
    values.inject(0) {|sum, value| sum + value} / values.size
  end

  def self.sd(values)
    mean_value = mean(values)
    Math.sqrt(mean(values.map {|value| (value - mean_value) ** 2}))
  end

  def self.covariance(x_values, y_values)
    x_mean = mean(x_values)
    y_mean = mean(y_values)
    mean([x_values, y_values].transpose.map {|x,y| (x-x_mean) * (y-y_mean)})
  end
end

if __FILE__ == $0
  puts PearsonCorrelation.similarity_score(*movie_ratings_from('Lisa Rose', 'Gene Seymour'))
end