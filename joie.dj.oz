% Hymne à la joie.
local
   Tune = [b b c d d c b a g3 g3 a b]
   End1 = [etirer(facteur:1.5 b) etirer(facteur:0.5 a) etirer(facteur:2.0 a)]
   End2 = [etirer(facteur:1.5 a) etirer(facteur:0.5 g3) etirer(facteur:2.0 g3)]
   Interlude = [a a b g3 a etirer(facteur:0.5 [b c])
                    b g3 a etirer(facteur:0.5 [b c])
                b a g3 a etirer(facteur:2.0 d3) ]

   % Ceci n'est pas une musique
   Partition = [Tune End1 Tune End2 Interlude Tune End2]
in
   % Ceci est une musique :-)
   [partition(Partition)]
end

