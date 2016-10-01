(ns ncurses
  (:require [pixie.ffi-infer :refer :all]
            [pixie.ffi :as ffi]
            [pixie.time :refer [time]]
            [pixie.walk :as walk]
            [bewitch.core :as bewitch]))


(def game-map-input ["#### ######## "
                     "#..# #......# "
                     "#..###...$..##"
                     "#........... #"
                     "#..###......# "
                     "#..# #......# "
                     "#### ######## "])

(def game-map (mapv (fn [l]
                      (mapv (fn [c]
                              (condp = c
                                \# {:char \# :color [:red :black]}
                                \. {:char \. :color [:green :black]}
                                
                                c))
                            l))
                   game-map-input))


(defn render-score-window [window {:keys [player turns]}]
  (-> window
      (bewitch/render 1 1 (str "Name: " (:name player)))
      (bewitch/render 2 1 "Score: 100")
      (bewitch/render 3 1 "HP: 20/20")
      (bewitch/render 4 1 "MP: 10/10")
      (bewitch/render 5 1 (str "Turns: " turns))))

(defn render-game-map [window]
  (for [[y line] (map vector (range) game-map)]
    (for [[x c] (map vector (range) line)]
      (bewitch/render window (inc y) (inc x) c))))

(defn handle-input [game-state ch]
  (condp = ch
    :key/up
    (update-in game-state [:player :y] dec)

    :key/down
    (update-in game-state [:player :y] inc)

    :key/left
    (update-in game-state [:player :x] dec)

    :key/right
    (update-in game-state [:player :x] inc)

    game-state))

(def initial-state {:player {:x 1 :y 1 :renderable {:color [:blue :black] :char "@"}}
                    :turns 0
                    :screen :intro-screen})

(defmulti handle-screen :screen)

(defmethod handle-screen :map-screen [{:keys [player turns] :as game-state}]
  (bewitch/with-window [score-win (-> (bewitch/new-window 10 30 0 50)
                                      (bewitch/render-box))
                        play-win (-> (bewitch/new-window 20 40 0 0)
                                     (bewitch/render-box))]
    
    (render-game-map play-win)
    

    (bewitch/render play-win  (:y player) (:x player) (:renderable player))
    
    (render-score-window score-win game-state))
  
  (let [ch (bewitch/getch)]
    (if (= \q ch)
      nil
      (-> game-state
          (handle-input ch)
          (update-in [:turns] inc)))))

(defmethod handle-screen :intro-screen [game-state]
  (bewitch/with-window [intro-win (bewitch/new-window 5 50 0 0)]

    (bewitch/render intro-win 0 0 "What is thy name, adventurer? ")
    (-> game-state
        (assoc-in [:player :name] (-> intro-win
                                      (bewitch/render 3 4 {:color [:blue :blue] :string "               "})
                                      (bewitch/move 3 4)
                                      (bewitch/read-string)))
        (assoc-in [:screen] :map-screen))))

(let [scr (bewitch/init)]
  (loop [game-state initial-state]
    (bewitch/refresh scr)
    (if-let [new-state (handle-screen game-state)] 
      (recur new-state)
      nil)) 
  (bewitch/destroy scr))
