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
  
  def self.get_recommendations(person, &similarity_score)
    return [] unless CRITICS.has_key? person
    
    similarity_scores = Hash[CRITICS.keys.select {|e| e != person}.map do |another_person|
      [another_person, similarity_score.call(movie_ratings_from(person, another_person))]
    end]
    
    movies = Hash[CRITICS.keys.select {|e| e != person}.map do |another_person|
      new_movies = CRITICS[another_person].keys.reject {|movie| CRITICS[person].keys.include? movie}
      [another_person, new_movies] unless new_movies.empty?
    end]
    
    weighted_ratings = Hash[movies.map do |person, movies|
      [person, Hash[movies.map {|movie| [movie, CRITICS[person][movie] * similarity_scores[person]]}]] if similarity_scores[person] > 0
    end]
    
    total_weighted_ratings = weighted_ratings.reduce({}) do |total, weighted_rating|
      weighted_rating[1].each {|movie, rating| total[movie] = (total[movie]||0) + rating}
      total
    end
    
    total_similarity_scores = weighted_ratings.reduce({}) do |total, weighted_rating|
      weighted_rating[1].each {|movie, rating| total[movie] = (total[movie]||0) + similarity_scores[weighted_rating[0]]}
      total
    end

    movies.values.flatten.uniq.reduce({}) do |normalised, movie|
      normalised[movie] = total_weighted_ratings[movie] / total_similarity_scores[movie]
      normalised
    end
  end
  
  def self.top_matches(person, limit = 5, &similarity_score)
    return [] unless CRITICS.has_key? person
    CRITICS.keys.select {|e| e != person}.map do |another_person|
      [another_person, similarity_score.call(movie_ratings_from(person, another_person))]
    end.sort_by {|name, score| score}.reverse[0...limit]
  end
  
  def self.movie_ratings_from(first_person, second_person)
    from_first_person = CRITICS[first_person].find_all {|rating| CRITICS[second_person].has_key? rating[0]}.sort.map {|rating| rating[1]}
    from_second_person = CRITICS[second_person].find_all {|rating| CRITICS[first_person].has_key? rating[0]}.sort.map {|rating| rating[1]}
    [from_first_person, from_second_person]
  end
end

if __FILE__ == $0
  require File.dirname(__FILE__) + '/pearson_correlation'
  puts Recommendations.get_recommendations('Toby') {|ratings1, ratings2| PearsonCorrelation.similarity_score(ratings1, ratings2)}
end