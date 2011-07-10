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

def movie_ratings_from(first_person, second_person)
  from_first_person = CRITICS[first_person].find_all {|rating| CRITICS[second_person].has_key? rating[0]}.sort.map {|rating| rating[1]}
  from_second_person = CRITICS[second_person].find_all {|rating| CRITICS[first_person].has_key? rating[0]}.sort.map {|rating| rating[1]}
  [from_first_person, from_second_person]
end