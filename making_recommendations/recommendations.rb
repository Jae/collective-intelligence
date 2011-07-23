class Recommendations
  def self.get_recommendations(receiver, ratings, &similarity_score)
    return [] unless ratings.has_key? receiver
    
    similarity_scores = Hash[ratings.keys.reject {|e| e == receiver}.map do |critic|
      [critic, similarity_score.call(common_ratings_from(receiver, critic, ratings))]
    end]
    
    recommended_by_critics = Hash[ratings.keys.reject {|e| e == receiver}.map do |critic|
      recommendations = ratings[critic].keys.reject {|rated| ratings[receiver].keys.include? rated}
      [critic, recommendations] unless recommendations.empty?
    end]
    
    weighted_ratings = Hash[recommended_by_critics.map do |critic, recommendations|
      [critic, Hash[recommendations.map {|recommended| [recommended, ratings[critic][recommended] * similarity_scores[critic]]}]] if similarity_scores[critic] > 0
    end]
    
    total_weighted_ratings = weighted_ratings.reduce({}) do |total, weighted_rating|
      weighted_rating[1].each {|recommended, rating| total[recommended] = (total[recommended]||0) + rating}
      total
    end
    
    total_similarity_scores = weighted_ratings.reduce({}) do |total, weighted_rating|
      weighted_rating[1].each {|recommended, rating| total[recommended] = (total[recommended]||0) + similarity_scores[weighted_rating[0]]}
      total
    end

    total_weighted_ratings.keys.reduce({}) do |normalised, recommended|
      normalised[recommended] = total_weighted_ratings[recommended] / total_similarity_scores[recommended]
      normalised
    end.to_a.sort_by {|e| e[1]}.reverse
  end
  
  def self.top_matches(receiver, ratings, limit = 5, &similarity_score)
    return [] unless ratings.has_key? receiver
    ratings.keys.select {|e| e != receiver}.map do |critic|
      [critic, similarity_score.call(common_ratings_from(receiver, critic, ratings))]
    end.sort_by {|name, score| score}.reverse[0...limit]
  end
  
  def self.common_ratings_from(critic1, critic2, ratings)
    from_critic1 = ratings[critic1].find_all {|rating| ratings[critic2].has_key? rating[0]}.sort.map {|rating| rating[1]}
    from_critic2 = ratings[critic2].find_all {|rating| ratings[critic1].has_key? rating[0]}.sort.map {|rating| rating[1]}
    [from_critic1, from_critic2]
  end
  
  def self.transpose(ratings)
    ratings.reduce({}) do |transposed, rating|
      rating[1].each do |recommended, score|
        (transposed[recommended]||={})[rating[0]] = score
      end
      transposed
    end
  end
end

if __FILE__ == $0
  require File.dirname(__FILE__) + '/pearson_correlation'
  require File.dirname(__FILE__) + '/movie_ratings'
  puts Recommendations.get_recommendations('Toby', Movie::RATINGS) {|ratings1, ratings2| PearsonCorrelation.similarity_score(ratings1, ratings2)}.inspect
  puts Recommendations.top_matches('Superman Returns', Recommendations.transpose(Movie::RATINGS)) {|ratings1, ratings2| PearsonCorrelation.similarity_score(ratings1, ratings2)}.inspect
  puts Recommendations.get_recommendations('Just My Luck', Recommendations.transpose(Movie::RATINGS)) {|ratings1, ratings2| PearsonCorrelation.similarity_score(ratings1, ratings2)}.inspect
end