# Make breakout in 1 hour

(import freja/state)
(import freja/event/subscribe :as s)
(import freja/hiccup :as hc)
(use freja/defonce)
(use freja/flow)

(unless (state/editor-state :inited-audio)
  (init-audio-device)
  (put state/editor-state :inited-audio true))

(defonce sound (load-sound "assets/lugnanerej.mp3"))

(when-let [fib (get-in (dyn 'state) [:ref 0 :fib])]
  (ev/cancel fib "stop timer"))

(def state @{:freja/label "Timer"
             :time 0
             :total-time 60})

(defn refresh-timer
  [minutes starting-seconds]

  # relevant when clicking `Go` again
  (s/put! state :alarm false)

  (fn []
    (loop [i :range [starting-seconds (inc (* 60 minutes))]]
      (when (state :paused)
        (yield :paused))

      (s/put! state :time i)
      (s/put! state/editor-state :force-refresh true)
      (ev/sleep 1))
    (play-sound sound)
    (s/put! state :alarm true)
    (s/put! state/editor-state :force-refresh true)))

(defn start-timer
  [minutes &keys {:start start}]
  (default start [0 0])
  (def [m s] start)
  (def starting-seconds (+ (* m 60) s))

  (when-let [fib (state :fib)]
    (ev/cancel fib "stop timer"))

  (put state :fib (ev/call (refresh-timer minutes starting-seconds))))

(defn timer
  [state]
  (def {:time time
        :total-time tt
        :alarm alarm} state)
  [:block {}
   (do comment
     [:padding {:all 2 :right 4 :left 100}
      [:row {}
       [:clickable {:on-click (fn [_] (start-timer tt))}
        [:padding {:right 12}
         [:text {:size 20
                 :color [0.5 0.5 0.5]
                 :text "Go"}]]]

       [:clickable {:on-click (fn [_]
                                (s/put! state :paused (not (state :paused)))
                                (unless (state :paused)
                                  (ev/go (state :fib)))
                                (s/put! state/editor-state :force-refresh true))}

        [:padding {:right 12}
         [:text {:size 20
                 :color [0.5 0.5 0.5]
                 :text (if (state :paused)
                         "Continue"
                         "Pause")}]]]

       [:text {:color (if alarm :green [0.6 0.6 0.6])
               :font "MplusCode"
               :size (if alarm
                       100
                       # 60
                       20)
               :text (string/format "Tomato: %02d:%02d / %02d:%02d"
                                    # "Break timer: %02d:%02d / 10:00"
                                    (math/floor (/ time 60))
                                    (mod time 60)
                                    tt
                                    0)}]]])])


(use freja/flow)
(do
  (set-window-position (- 1920 400) (- 1080 80))
  (hc/new-layer :timer timer state)
  #(set-window-state :window-undecorated)
  (set-window-state :window-topmost)
  (start-timer 60 :start [0 0]))

(comment
  (start-timer 25)
  (s/put! state/editor-state :other [timer state])

  (filter |(string/find "window" $) (keys (curenv)))

  (clear-window-state :window-undecorated)

  (hc/remove-layer :menu)
  #
)
p