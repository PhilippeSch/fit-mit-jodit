import Foundation

struct CatalogExercise: Hashable, Sendable {
    let id: String
    let german: String
    let english: String
}

enum ExerciseCatalog {
    /// 60 gängige Gruppenfitness-Übungen und 10 Dehnübungen, alphabetisch nach deutschem Namen.
    static let all: [CatalogExercise] = [
        CatalogExercise(id: "butt_kicks", german: "Anfersen", english: "Butt Kicks"),
        CatalogExercise(id: "arm_circles", german: "Armkreisen", english: "Arm Circles"),
        CatalogExercise(id: "twisting_lunges", german: "Ausfallschritte mit Drehung", english: "Twisting Lunges"),
        CatalogExercise(id: "reverse_lunges", german: "Ausfallschritte rückwärts", english: "Reverse Lunges"),
        CatalogExercise(id: "forward_lunges", german: "Ausfallschritte vorwärts", english: "Forward Lunges"),
        CatalogExercise(id: "bear_crawl", german: "Bärengang", english: "Bear Crawl"),
        CatalogExercise(id: "lying_leg_raises", german: "Beinheben liegend", english: "Lying Leg Raises"),
        CatalogExercise(id: "flutter_kicks", german: "Beinschere", english: "Flutter Kicks"),
        CatalogExercise(id: "mountain_climbers", german: "Bergsteiger", english: "Mountain Climbers"),
        CatalogExercise(id: "bicycle_crunches", german: "Bicycle Crunches", english: "Bicycle Crunches"),
        CatalogExercise(id: "bird_dog", german: "Bird Dog", english: "Bird Dog"),
        CatalogExercise(id: "biceps_curls", german: "Bizepscurls", english: "Biceps Curls"),
        CatalogExercise(id: "chest_stretch", german: "Brust dehnen", english: "Chest Stretch"),
        CatalogExercise(id: "burpees", german: "Burpees", english: "Burpees"),
        CatalogExercise(id: "crunches", german: "Crunches", english: "Crunches"),
        CatalogExercise(id: "dead_bug", german: "Dead Bug", english: "Dead Bug"),
        CatalogExercise(id: "diamond_push_ups", german: "Diamant-Liegestütze", english: "Diamond Push-ups"),
        CatalogExercise(id: "chair_dips", german: "Dips am Stuhl", english: "Chair Dips"),
        CatalogExercise(id: "donkey_kicks", german: "Donkey Kicks", english: "Donkey Kicks"),
        CatalogExercise(id: "single_leg_glute_bridge", german: "Einbeinige Glute Bridge", english: "Single-Leg Glute Bridge"),
        CatalogExercise(id: "fire_hydrants", german: "Fire Hydrants", english: "Fire Hydrants"),
        CatalogExercise(id: "figure_four_stretch", german: "Gesäss dehnen", english: "Figure-Four Stretch"),
        CatalogExercise(id: "glute_bridge", german: "Glute Bridge", english: "Glute Bridge"),
        CatalogExercise(id: "good_mornings", german: "Good Mornings", english: "Good Mornings"),
        CatalogExercise(id: "hammer_curls", german: "Hammer Curls", english: "Hammer Curls"),
        CatalogExercise(id: "jumping_jacks", german: "Hampelmann", english: "Jumping Jacks"),
        CatalogExercise(id: "hip_thrusts", german: "Hip Thrusts", english: "Hip Thrusts"),
        CatalogExercise(id: "high_knees", german: "Hohe Knie", english: "High Knees"),
        CatalogExercise(id: "hollow_hold", german: "Hollow Hold", english: "Hollow Hold"),
        CatalogExercise(id: "hip_flexor_stretch", german: "Hüftbeuger dehnen", english: "Hip Flexor Stretch"),
        CatalogExercise(id: "inchworm", german: "Inchworm", english: "Inchworm"),
        CatalogExercise(id: "cat_cow", german: "Katze-Kuh", english: "Cat-Cow"),
        CatalogExercise(id: "childs_pose", german: "Kindhaltung", english: "Child's Pose"),
        CatalogExercise(id: "squats", german: "Kniebeugen", english: "Squats"),
        CatalogExercise(id: "jump_squats", german: "Kniebeugen mit Sprung", english: "Jump Squats"),
        CatalogExercise(id: "cossack_squats", german: "Kosaken-Kniebeugen", english: "Cossack Squats"),
        CatalogExercise(id: "dumbbell_deadlift", german: "Kreuzheben mit Kurzhanteln", english: "Dumbbell Deadlift"),
        CatalogExercise(id: "dumbbell_row", german: "Kurzhantel-Rudern", english: "Dumbbell Row"),
        CatalogExercise(id: "push_ups", german: "Liegestütze", english: "Push-ups"),
        CatalogExercise(id: "knee_push_ups", german: "Liegestütze auf den Knien", english: "Knee Push-ups"),
        CatalogExercise(id: "hamstring_stretch", german: "Oberschenkel hinten dehnen", english: "Hamstring Stretch"),
        CatalogExercise(id: "quad_stretch", german: "Oberschenkel vorne dehnen", english: "Quad Stretch"),
        CatalogExercise(id: "pike_push_ups", german: "Pike Push-ups", english: "Pike Push-ups"),
        CatalogExercise(id: "plank", german: "Plank", english: "Plank"),
        CatalogExercise(id: "plank_jacks", german: "Plank Jacks", english: "Plank Jacks"),
        CatalogExercise(id: "plank_shoulder_taps", german: "Plank mit Schulterberührung", english: "Plank Shoulder Taps"),
        CatalogExercise(id: "russian_twists", german: "Russian Twists", english: "Russian Twists"),
        CatalogExercise(id: "shoulder_stretch", german: "Schulter dehnen", english: "Shoulder Stretch"),
        CatalogExercise(id: "shoulder_press", german: "Schulterdrücken", english: "Shoulder Press"),
        CatalogExercise(id: "swimmer", german: "Schwimmer", english: "Swimmer"),
        CatalogExercise(id: "jump_rope_no_rope", german: "Seilspringen ohne Seil", english: "Jump Rope (No Rope)"),
        CatalogExercise(id: "lateral_raises", german: "Seitheben", english: "Lateral Raises"),
        CatalogExercise(id: "side_lunges", german: "Seitliche Ausfallschritte", english: "Side Lunges"),
        CatalogExercise(id: "side_leg_raises", german: "Seitliches Beinheben", english: "Side Leg Raises"),
        CatalogExercise(id: "side_plank", german: "Seitstütz", english: "Side Plank"),
        CatalogExercise(id: "sit_ups", german: "Sit-ups", english: "Sit-ups"),
        CatalogExercise(id: "skater_hops", german: "Skater", english: "Skater Hops"),
        CatalogExercise(id: "spiderman_push_ups", german: "Spiderman-Liegestütze", english: "Spiderman Push-ups"),
        CatalogExercise(id: "jump_lunges", german: "Sprungausfallschritte", english: "Jump Lunges"),
        CatalogExercise(id: "sumo_squats", german: "Sumo-Kniebeugen", english: "Sumo Squats"),
        CatalogExercise(id: "superman", german: "Superman", english: "Superman"),
        CatalogExercise(id: "thrusters", german: "Thrusters", english: "Thrusters"),
        CatalogExercise(id: "toe_touches", german: "Toe Touches", english: "Toe Touches"),
        CatalogExercise(id: "triceps_stretch", german: "Trizeps dehnen", english: "Triceps Stretch"),
        CatalogExercise(id: "overhead_triceps_extension", german: "Trizepsstrecken über Kopf", english: "Overhead Triceps Extension"),
        CatalogExercise(id: "tuck_jumps", german: "Tuck Jumps", english: "Tuck Jumps"),
        CatalogExercise(id: "v_ups", german: "V-Ups", english: "V-Ups"),
        CatalogExercise(id: "calf_stretch", german: "Waden dehnen", english: "Calf Stretch"),
        CatalogExercise(id: "calf_raises", german: "Wadenheben", english: "Calf Raises"),
        CatalogExercise(id: "wall_sit", german: "Wandsitzen", english: "Wall Sit"),
    ]

    /// Name in der aktuellen App-Sprache (Deutsch bei "de", sonst Englisch).
    static func localizedName(_ e: CatalogExercise, locale: Locale = .current) -> String {
        locale.language.languageCode?.identifier == "de" ? e.german : e.english
    }

    /// Suche ohne Gross-/Kleinschreibung und ohne Akzente in beiden Sprachen.
    static func search(_ query: String) -> [CatalogExercise] {
        let q = fold(query.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !q.isEmpty else { return all }
        return all.filter { fold($0.german).contains(q) || fold($0.english).contains(q) }
    }

    private static func fold(_ s: String) -> String {
        s.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }
}
