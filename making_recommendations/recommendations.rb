class Recommendations
  def self.get_itembased_recommendations(receiver, ratings, item_similarity_scores)
    return [] unless ratings.has_key? receiver
    
    weighted_ratings = Hash[ratings[receiver].map do |item, rating|
      [item, Hash[item_similarity_scores[item].map do |alternative, similarity_score| 
        [alternative, rating * similarity_score] unless ratings[receiver][alternative] or similarity_score < 0
      end]]
    end]
    
    total_weighted_ratings = weighted_ratings.values.reduce({}) do |total, alternative_weighted_ratings|
      alternative_weighted_ratings.each {|alternative, weighted_rating| total[alternative] = (total[alternative]||0) + weighted_rating}
      total
    end
    
    total_similarity_scores = weighted_ratings.reduce({}) do |total, weighted_rating|
      item, alternative_weighted_ratings = *weighted_rating
      alternative_weighted_ratings.each {|alternative, weighted_rating| total[alternative] = (total[alternative]||0) + item_similarity_scores[item][alternative]}
      total
    end
    
    Hash[total_weighted_ratings.keys.map do |alternative|
      [alternative, total_weighted_ratings[alternative] / total_similarity_scores[alternative]] unless total_similarity_scores[alternative] == 0
    end].sort_by {|alternative, normalised_similarity_score| normalised_similarity_score}.reverse
  end
  
  def self.get_recommendations(receiver, ratings, &similarity_score)
    return [] unless ratings.has_key? receiver
    
    similarity_scores = Hash[ratings.keys.reject {|e| e == receiver}.map do |critic|
      [critic, similarity_score.call(common_ratings_from(receiver, critic, ratings))]
    end]
    
    weighted_ratings = Hash[ratings.map do |critic, alternatives_by_critic|
      [critic, Hash[alternatives_by_critic.map do |alternative, rating| 
        [alternative, rating * similarity_scores[critic]] unless ratings[receiver][alternative] or similarity_scores[critic] < 0
      end]] unless critic == receiver
    end]
    
    total_weighted_ratings = weighted_ratings.values.reduce({}) do |total, alternative_weighted_ratings|
      alternative_weighted_ratings.each {|alternative, weighted_rating| total[alternative] = (total[alternative]||0) + weighted_rating}
      total
    end
    
    total_similarity_scores = weighted_ratings.reduce({}) do |total, weighted_ratings|
      critic, alternative_weighted_ratings = *weighted_ratings
      alternative_weighted_ratings.each {|alternative, weighted_rating| total[alternative] = (total[alternative]||0) + similarity_scores[critic]}
      total
    end

    Hash[total_weighted_ratings.keys.map do |alternative|
      [alternative, total_weighted_ratings[alternative] / total_similarity_scores[alternative]] unless total_similarity_scores[alternative] == 0
    end].sort_by {|alternative, normalised_similarity_score| normalised_similarity_score}.reverse
  end
  
  def self.similarity_scores(ratings, limit = 5, &similarity_score)
    Hash[ratings.keys.map do |critic|
      [critic, Recommendations.top_matches(critic, ratings, limit, &similarity_score)]
    end]
  end
  
  def self.top_matches(critic, ratings, limit = 5, &similarity_score)
    return [] unless ratings.has_key? critic
    Hash[ratings.keys.select {|e| e != critic}.map do |other_critic|
      [other_critic, similarity_score.call(common_ratings_from(critic, other_critic, ratings))]
    end.sort_by {|critic, score| score}.reverse[0...limit]]
  end
  
  def self.common_ratings_from(critic1, critic2, ratings)
    from_critic1 = ratings[critic1].find_all {|recommended, score| ratings[critic2].has_key? recommended}.sort_by {|recommended, score| recommended}.map {|recommended, score| score}
    from_critic2 = ratings[critic2].find_all {|recommended, score| ratings[critic1].has_key? recommended}.sort_by {|recommended, score| recommended}.map {|recommended, score| score}
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
