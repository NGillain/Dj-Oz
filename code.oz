% Vous ne pouvez pas utiliser le mot-clé 'declare'.
local Mix Interprete Projet CWD in
   % CWD contient le chemin complet vers le dossier contenant le fichier 'code.oz'
   % modifiez sa valeur pour correspondre à votre système.
   CWD = {Property.condGet 'testcwd' 'C:\\Users\\Edwin\\Documents\\ProjetOZ\\Projet2014\\Projet2014\\'}

   % Si vous utilisez Mozart 1.4, remplacez la ligne précédente par celle-ci :
   % [Projet] = {Link ['Projet2014_mozart1.4.ozf']}
   %
   % Projet fournit quatre fonctions :
   % {Projet.run Interprete Mix Music 'out.wav'} = ok OR error(...) 
   % {Projet.readFile FileName} = AudioVector OR error(...)
   % {Projet.writeFile FileName AudioVector} = ok OR error(...)
   % {Projet.load 'music_file.dj.oz'} = La valeur oz contenue dans le fichier chargé (normalement une <musique>).
   %
   % et une constante :
   % Projet.hz = 44100, la fréquence d'échantilonnage (nombre de données par seconde)
   [Projet] = {Link [CWD#'Projet2014_mozart2.ozf']}

   local
      %Audio = {Projet.readFile CWD#'wave/animaux/cow.wav'}
     
      fun{Flatten L} % réduit les listes de listes de ... en une liste simple
	 case L
	 of nil then nil
	 [] H|T then {Append {Flatten H} {Flatten T}}
	 else [L]
	 end
      end
      
      fun{ComputeDemiTons Note} % calcule la hauteur d'une note par rapport à a4
	 local Diff Alt
	 in
	    case Note.nom of a then Diff=0
	    [] b then Diff=2
	    [] c then Diff=~9
	    [] d then Diff=~7
	    [] e then Diff=~5
	    [] f then Diff=~4
	    [] g then Diff=~2
	    end
	    if Note.alteration=='#' then Alt=1 % permet de gérer la dièse
	    else Alt=0
	    end
	    (Note.octave-4)*12+Diff+Alt
	 end
      end
      	
      
      fun {ToNote Note} % crée un enregistrement note à partir d'une note écrite sous forme d'un atom
	 case Note
	 of Nom#Octave then note(nom:Nom octave:Octave alteration :'#')
	 [] Atom then
	    case {AtomToString Atom}
	    of [N] then note(nom:Atom octave:4 alteration:none)
	    [] [N O] then note(nom:{StringToAtom [N]}
			       octave:{StringToInt [O]}
			       alteration:none)
	    end
	 end
      end
      
      fun{NoteToEchantillon Note} % transforme une note étendue (Note) en un record échantillon
	 case Note
	 of silence then silence(duree:1.0)
	 [] note(nom:X octave:Y alteration:Z) then echantillon(hauteur:{ComputeDemiTons Note} duree:1.0 instrument:none)
	 % Calcule la hauteur de Note
	 end
      end
      
      fun{Bourdon X Y} % transformation qui met à la même hauteur que X toutes les notes des échantillons de Y
	 case Y of nil then nil
	 []H|T then 
	    case X of silence then silence(duree:H.duree)|{Bourdon X T}
	    [] note(nom:N octave:Octave alteration:A) then echantillon(hauteur:{ComputeDemiTons X} duree:H.duree instrument:H.instrument)|{Bourdon X T}
	    end
	 end
      end
      
      fun{Muet X} % transforme toutes les notes de la partition en silence
	 {Bourdon silence X}
      end
      
      fun{Etirer X Y} % allonge la durée d'un échantillon d'un facteur X
	 case Y of nil then nil
	 []H|T then
	    case H of silence(duree:D) then silence(duree:D*X)|{Etirer X T}
	    []echantillon(hauteur:Z duree:Y instrument:I) then echantillon(hauteur:Z duree:Y*X instrument:I)|{Etirer X T}
	    end
	 end
      end
      
      fun{DureePart X Acc} % calcule la durée d'une partition
	 case X of nil then Acc
	 []H|T then {DureePart T Acc+H.duree}
	 end
      end
      
      fun{Duree X Y} % étire toutes les notes de la partition pour qu'elle dure X secondes
	 case Y of nil then nil
	 []H|T then {Etirer X/{DureePart Y 0.0} Y}
	 end
      end
      
      fun{Transpose X Y} % augmente chaque note de la partition de X demi-tons
	 case Y of nil then nil
	 []H|T then
	    case H of silence(duree:D) then silence(duree:D)|{Transpose X T}
	    []echantillon(hauteur:H duree:Y instrument:I) then echantillon(hauteur:H+X duree:Y instrument:I)|{Transpose X T}
	    end
	 end
      end

       fun{ToVector Ech} % transforme un échantillon en vecteur audio
	 local
	    Vecteur
	    Pi=3.14159
	    Long=44100.0*Ech.duree
	    Freq
	    case Ech of silence(duree:X) then Freq=0.0 % un silence ne renvoit rien
	    []echantillon(hauteur:X duree:Y instrument:I) then
	       Freq={Pow 2.0 {IntToFloat X}/12.0}*440.0
	    end
	    fun{Vecteur Acc}
	       if (Acc=<Long) then
		  0.5*{Sin 2.0*Pi*Freq*Acc/44100.0}|{Vecteur Acc+1.0}
	       else
		  nil
	       end
	    end
	 in
	    {Vecteur 1.0}
	 end
      end

      fun{VoiceToVector L} % transforme une liste d'echantillon en vecteur audio
	 case L of nil then nil
	 [] H|T then
	    {Flatten  {ToVector H}|{VoiceToVector T}}
	 end
      end

      fun{AddVector V1 V2}  
      % additionne deux vecteurs de tailles différentes en ajoutant du silence si nécessaire
	 if V1\=nil andthen V2\=nil then V1.1+V2.1|{AddVector V1.2 V2.2}
	 elseif V1==nil andthen V2\=nil then V2.1|{AddVector nil V2.2}
	 elseif V2==nil andthen V1\=nil then V1.1|{AddVector V1.2 nil}
	 else nil
	 end
      end

      fun{Ponderate N M} % pondere un vecteur audio avec N
	 case M of nil then nil
	 [] H|T then
	    N*H|{Ponderate N T}
	 end
      end

      fun{ListVector X} % cree une liste contenant des listes representant les vecteurs audio a sommer
	 case X of nil then nil
	 [] H|T then
	    case H
	    of N#M then {Ponderate N {Mix Interprete M}}|{ListVector T}
	    end
	 end
      end


      fun{MergeToVector P} % merge les vecteurs audio contenu dans P sous forme de liste d'atom 'Coeff#Music'
	 local
	    M={ListVector P}
	    fun{Somme X Acc} 
	       case X of nil then Acc
	       []H|T then {Somme T {AddVector H Acc}}
	       end
	    end
	 in
	    {Somme M nil}
	 end
      end

      fun{RepetitionNb Nbre Music} % Repete Nbre fois la musique Music
	 if(Nbre>=0) then
	    {Flatten Music|{RepetitionNb Nbre-1 Music}}
	 else
	    nil
	 end
      end
      
      fun{RepetitionDu Duree X} % repete une musique X pendant un temps Duree
	 local
	    fun{Repet Y  Acc}	 
	       if(Acc=<Duree*44100.0) then
		  case Y of nil then {Repet X Acc+1.0}
		  []H|T then H|{Repet T Acc+1.0}
		  end
	       else
		  nil
	       end
	    end
	 in
	    {Repet X 0.0}
	 end	
      end

      fun{ToVecteurMerge Delai Deca Repet M Comp}
      % transforme un vecteur audio en une liste de vecteur audio utilisable par Merge
	 if(Comp=<{IntToFloat Repet}) then
	    if(Comp==0.0) then
	       {Pow Deca Comp}#M |{ToVecteurMerge Delai Deca Repet M Comp+1.0}
	    else
	       {Pow Deca Comp}#{Flatten [voix([silence(duree:Delai*Comp)]) M]} |{ToVecteurMerge Delai Deca Repet M Comp+1.0}
	    end
	 else
	    nil
	 end
      end
       
      fun{SumOfFact List Acc} % Somme des coefficients pour merge
	 case List of nil then Acc
	 []H|T then
	    case H of A#B then {SumOfFact T Acc+A}
	    end
	 end
      end
       
      fun{Creation Delai Deca Repetition Music}
      % pondère les vecteurs audio afin de pouvoir les merger
	 local
	    X={ToVecteurMerge Delai Deca Repetition Music 0.0}
	    Y={SumOfFact X 0.0}
	    fun{ReAffect X Y}
	       case X of nil then nil
	       [] H|T then
		  case H of A#B then A/Y#B |{ReAffect T Y}
		  end
	       end
	    end
	 in
	    {ReAffect X Y}
	 end
      end


      fun{Renverser M} % Renverse le vecteur audio M et permet de creer ainsi un message subliminal
	 local
	    fun{Aux M Acc}
	       case M of nil then Acc
	       [] H|T then
		  {Aux T H|Acc}
	       end
	    end
	 in
	    {Aux M nil}
	 end
      end

      fun{Clip F1 F2 M} 
      % assigne une intensité maximale et minimale tel que les valeurs du vecteur audio
      % sont comprises entre F1 et F2
	 case M of nil then nil
	 [] H|T then
	    if H>F1 andthen H<F2 then H|{Clip F1 F2 T}
	    elseif H<F1 then F1|{Clip F1 F2 T}
	    elseif H>F2 then F2|{Clip F1 F2 T}
	    end
	 end
      end

      fun{Couper S1 S2 M}
      % Coupe le morceau aux temps indiqués. Si les temps sont en dehors de la bande sonore
      % on ajoute du silence
	 local
	    Debut=S1*44100.0
	    Fin=S2*44100.0
	    fun{Aux Debut M Comp}
	       if Debut<0.0 then 0.0|{Aux Debut+1.0 M Comp}
	       % si on commence avant, il faut ajouter du silence
	       elseif Comp<Debut then
		 case M
		   of H|T then {Aux Debut T Comp+1.0} 
		   % on continue jusqu'à trouver le début du morceau à couper
		   [] nil then nil % le morceau est vide
		 end
	       elseif Comp>=Debut andthen Comp=<Fin then
		  case M
		    of H|T then H|{Aux Debut T Comp+1.0}
		    % on coupe la valeur et on la garde
		    [] nil then 0.0|{Aux Debut nil Comp+1.0}
		    % on doit continuer avec du silence même si le morceau est fini
		  end
	       elseif Comp>Fin then nil  %din du découpage
	       end
	    end
	 in
	    {Aux Debut M 1.0}
	 end
      end

      fun{Fondu S1 S2 M} 
      % applique un fondu qui augmente l'intensité progressivement au début et diminue 
      % l'intensité de la fin
	 local
	    Debut=S1*44100.0
	    Fin=S2*44100.0 
	    L={IntToFloat {Length M}}
	    fun{Aux M Comp}
	       case M of nil then nil
	       []H|T then
		  if Comp=<(Debut-1.0) then (H*(Comp/(Debut-1.0)))|{Aux T Comp+1.0}
		  elseif Comp>(Debut-1.0) andthen (L-Comp-1.0)>(Fin-1.0) then H|{Aux T Comp+1.0}
		  else (H*(L-Comp-1.0)/(Fin-1.0))|{Aux T Comp+1.0}
		  end
	       end
	    end
	 in 
	    {Aux M 0.0}
	 end
      end

      fun{FonduEnchaine S M1 M2}
      % applique un fondu sur la fin du premier morceau et joue simultanément le 
      % deuxième morceau adoucit par un fondu sur le début de celui-ci
	 local
	    Temp=S*44100.0
	    L1={IntToFloat {Length M1}}
	    L2={IntToFloat {Length M2}}
	    fun{Aux M1 M2 Comp}
	       case M1 of nil then M2
	       [] H1|T1 then
		  if (L1-Comp-1.0)>(Temp-1.0) then H1|{Aux T1 M2 Comp+1.0}
		  elseif (L1-Comp-1.0)=<(Temp-1.0) andthen (Comp-L1+Temp)=<(Temp-1.0) then
		     case M2 of H2|T2 then
			H1*((L1-Comp-1.0)/(Temp-1.0))+H2*((Comp-L1+Temp)/(Temp-1.0))|{Aux T1 T2 Comp+1.0}
		     end
		  else M2
		  end
	       end
	    end
	 in
	    {Flatten {Aux M1 M2 0.0}}
	 end
      end

      fun{Dispatcher X} % dispatch qui renvoie chaque filtre à la fonction qui lui correspond
	 case X
	 of renverser(M) then {Renverser {Mix Interprete M}}
	 [] repetition(nombre:N M) then {RepetitionNb N {Mix Interprete M}}
	 [] repetition(duree:S M) then {RepetitionDu S {Mix Interprete M}}
	 [] clip(bas:F1 haut:F2 M) then {Clip F1 F2 {Mix Interprete M}}
	 [] echo(delai:S M) then {Mix Interprete [merge([0.5#M 0.5#{Flatten [voix([silence(duree: S)]) M]}])]}
	 [] echo(delai:S decadence:F M) then {Mix Interprete [merge([(1.0/(1.0+F))#M (F/(1.0+F))#{Flatten [voix([silence(duree:S)]) M]}])]}
	 [] echo(delai:S decadence:F repetition:N M) then {Mix Interprete [merge({Creation S F N M})]}
	 [] fondu(ouverture:S1 fermeture:S2 M) then {Fondu S1 S2 {Mix Interprete M}}
         [] fondu_enchaine(duree:S M1 M2) then {FonduEnchaine S {Mix Interprete M1} {Mix Interprete M2}}
	 [] couper(debut:S1 fin:S2 M) then {Couper S1 S2 {Mix Interprete M}}
	 end
      end

     
   
   in
      % Mix prends une musique et doit retourner un vecteur audio.
      fun {Mix Interprete Music} % permet de mixer de la musique (Music)
	 case Music
	 of nil then nil
	 []H|T then
	    case H
	    of voix(X) then {Flatten {VoiceToVector X}|{Mix Interprete T}}
	    []partition(P) then {Flatten {VoiceToVector {Interprete P}}|{Mix Interprete T}}
	    []wave(S) then {Flatten {Projet.readFile S}|{Mix Interprete T}}
	    []merge(L) then {Flatten {MergeToVector L}|{Mix Interprete T}}
	    else {Flatten {Dispatcher H}|{Mix Interprete T}}
	    end
	 end
      end

      % Interprete doit interpréter une partition
      fun {Interprete Partition} % permet de creer des partitions simples utilisables dans Mix
	 local P={Flatten Partition} in
	    case P of nil then nil
	    []H|T then
	       case H of muet(X) then {Flatten {Muet {Interprete X}}|{Interprete T}}
	       []duree(secondes:X Y) then {Flatten {Duree X {Interprete Y}}|{Interprete T}}
	       []etirer(facteur:X Y) then {Flatten {Etirer X {Interprete Y}}|{Interprete T}}
	       []bourdon(note:X Y) then {Flatten {Bourdon {ToNote X} {Interprete Y}}|{Interprete T}}
	       []transpose(demitons:X Y) then {Flatten {Transpose X {Interprete Y}}|{Interprete T}}
	       []A then {Flatten {NoteToEchantillon {ToNote A}}|{Interprete T}}
	       end
	    end
	 end
      end

      local 
	 Music = {Projet.load CWD#'example.dj.oz'}
      in
      % Votre code DOIT appeler Projet.run UNE SEULE fois.  Lors de cet appel,
      % vous devez mixer une musique qui démontre les fonctionalités de votre
      % programme.
      %
      % Si votre code devait ne pas passer nos tests, cet exemple serait le
      % seul qui ateste de la validité de votre implémentation.
	 {Browse {Projet.run Mix Interprete Music CWD#'out.wav'}}
      end
   end
end
