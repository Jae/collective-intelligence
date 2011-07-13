class Recommendations
  CRITICS = {
    'Lisa Rose' => {
      'Lady in the Water' => 2.5,
      'Snakes on a Plane' => 3.5,
      'Just My Luck' => 3.0,
      'Superman Returns' => 3.5,
      'You, Me and Dupree' => 2.5,
      'The Night Listener' => 3.0
    },
    'Gene Seymour' => {
      'Lady in the Water' => 3.0,
      'Snakes on a Plane' => 3.5,
      'Just My Luck' => 1.5,
      'Superman Returns' => 5.0,
      'The Night Listener' => 3.0,
      'You, Me and Dupree' => 3.5
    },
    'Michael Phillips' => {
      'Lady in the Water' => 2.5,
      'Snakes on a Plane' => 3.0,
      'Superman Returns' => 3.5,
      'The Night Listener' => 4.0
    },
    'Claudia Puig' => {
      'Snakes on a Plane' => 3.5,
      'Just My Luck' => 3.0,
      'Superman Returns' => 4.0,
      'The Night Listener' => 4.5,
      'You, Me and Dupree' => 2.5
    },
    'Mick LaSalle' => {
      'Lady in the Water' => 3.0,
      'Snakes on a Plane' => 4.0,
      'Just My Luck' => 2.0,
      'Superman Returns' => 3.0,
      'The Night Listener' => 3.0,
      'You, Me and Dupree' => 2.0
    },
    'Jack Matthews' => {
      'Lady in the Water' => 3.0,
      'Snakes on a Plane' => 4.0,
      'Superman Returns' => 5.0,
      'The Night Listener' => 3.0,
      'You, Me and Dupree' => 3.5
    },
    'Toby' => {
      'Snakes on a Plane' => 4.5,
      'You, Me and Dupree' => 1.0,
      'Superman Returns' => 4.0
    }
  }.freeze
  
  def self.get_recommendations(recommendee, ratings, &similarity_score)
    return [] unless ratings.has_key? recommendee
    
    similarity_scores = Hash[ratings.keys.reject {|e| e == recommendee}.map do |another_recommendee|
      [another_recommendee, similarity_score.call(common_ratings_from(recommendee, another_recommendee, ratings))]
    end]
    
    subjects_by_recommendee = Hash[ratings.keys.reject {|e| e == recommendee}.map do |another_recommendee|
      new_subjects = ratings[another_recommendee].keys.reject {|subject| ratings[recommendee].keys.include? subject}
      [another_recommendee, new_subjects] unless new_subjects.empty?
    end]
    
    weighted_ratings = Hash[subjects_by_recommendee.map do |recommendee, subjects|
      [recommendee, Hash[subjects.map {|subject| [subject, ratings[recommendee][subject] * similarity_scores[recommendee]]}]] if similarity_scores[recommendee] > 0
    end]
    
    total_weighted_ratings = weighted_ratings.reduce({}) do |total, weighted_rating|
      weighted_rating[1].each {|subject, rating| total[subject] = (total[subject]||0) + rating}
      total
    end
    
    total_similarity_scores = weighted_ratings.reduce({}) do |total, weighted_rating|
      weighted_rating[1].each {|subject, rating| total[subject] = (total[subject]||0) + similarity_scores[weighted_rating[0]]}
      total
    end

    subjects_by_recommendee.values.flatten.uniq.reduce({}) do |normalised, subject|
      normalised[subject] = total_weighted_ratings[subject] / total_similarity_scores[subject]
      normalised
    end.to_a.sort_by {|e| e[1]}.reverse
  end
  
  def self.top_matches(recommendee, ratings, limit = 5, &similarity_score)
    return [] unless ratings.has_key? recommendee
    ratings.keys.select {|e| e != recommendee}.map do |another_recommendee|
      [another_recommendee, similarity_score.call(common_ratings_from(recommendee, another_recommendee, ratings))]
    end.sort_by {|name, score| score}.reverse[0...limit]
  end
  
  def self.common_ratings_from(first_recommendee, second_recommendee, ratings)
    from_first_recommendee = ratings[first_recommendee].find_all {|rating| ratings[second_recommendee].has_key? rating[0]}.sort.map {|rating| rating[1]}
    from_second_recommendee = ratings[second_recommendee].find_all {|rating| ratings[first_recommendee].has_key? rating[0]}.sort.map {|rating| rating[1]}
    [from_first_recommendee, from_second_recommendee]
  end
  
  def self.transpose(ratings)
    ratings.reduce({}) do |transposed, rating|
      rating[1].each do |subject, score|
        (transposed[subject]||={})[rating[0]] = score
      end
      transposed
    end
  end
end

if __FILE__ == $0
  require File.dirname(__FILE__) + '/pearson_correlation'
  puts Recommendations.get_recommendations('Toby', Recommendations::CRITICS) {|ratings1, ratings2| PearsonCorrelation.similarity_score(ratings1, ratings2)}.inspect
  puts Recommendations.top_matches('Superman Returns', Recommendations.transpose(Recommendations::CRITICS)) {|ratings1, ratings2| PearsonCorrelation.similarity_score(ratings1, ratings2)}.inspect
end