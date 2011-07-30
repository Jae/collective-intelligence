require 'csv'
require 'yaml'
require File.join(File.dirname(__FILE__), %w[pearson_correlation])
require File.join(File.dirname(__FILE__), %w[euclidean_distance ])
require File.join(File.dirname(__FILE__), %w[recommendations])
require File.join(File.dirname(__FILE__), %w[movie_ratings])

def load_similarity_scores(similarity_scores_file, ratings=nil)
  if ratings
    similarity_scores = Recommendations.similarity_scores(ratings, 10) {|ratings1, ratings2| PearsonCorrelation.similarity_score(ratings1, ratings2)}
    File.open(similarity_scores_file, 'w' ) do |file|
      YAML.dump(similarity_scores, file)
    end
    similarity_scores
  else
    YAML.load_file(similarity_scores_file)
  end
end

ratings = {}
movies = Hash[CSV.read(File.join(File.dirname(__FILE__), %w[grouplens.org u.item]), :col_sep => "|").map {|movie| [movie[0], movie[1]]}]
CSV.foreach(File.join(File.dirname(__FILE__), %w[grouplens.org u.data]), :col_sep => "\t") do |line|
  user, movie, rating = "user#{line[0]}", movies[line[1]], line[2].to_f
  (ratings[user] ||= {})[movie] = rating
end
# movie_similarities = load_similarity_scores(File.join(File.dirname(__FILE__), %w[movie_similarity_scores]), Recommendations.transpose(ratings))
movie_similarities = load_similarity_scores(File.join(File.dirname(__FILE__), %w[movie_similarity_scores]))

movies_recommendations = Recommendations.get_itembased_recommendations('user87', ratings, movie_similarities)[0..20]
puts "user87's movie ratings: #{ratings["user87"].sort_by {|k,v|v}.reverse}"
puts "user87's movie recommendations: #{movies_recommendations}"