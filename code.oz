﻿% Vous ne pouvez pas utiliser le mot-clé 'declare'.
local Mix Interprete Projet CWD in
   % CWD contient le chemin complet vers le dossier contenant le fichier 'code.oz'
   % modifiez sa valeur pour correspondre à votre système.
   CWD = {Property.condGet 'testcwd' 'mettre son propre chemin pour le fichier :)'}

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
      Audio = {Projet.readFile CWD#'wave/animaux/cow.wav'}
      
      % Flatten réduit les listes de listes de ... en liste simple
      fun{Flatten L}
        case L
	of nil then nil
	[] H|T then {Append {Flatten H} {Flatten T}}
	else [L]
        end
      end
      
      fun{ComputeDemiTons Note}
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
	  if Note.alteration=='#' then Alt=1
	  else Alt=0
	  end
          (Note.octave-4)*12+Diff+Alt
        end
      end
      	
      
      fun {ToNote Note}
         case Note
	 of Nom#Octave then note (nom:Nom octave:Octave alteration :'#')
	 [] Atom then
	    case {AtomToString Atom}
	    of [N] then note (nom : Atom octave : 4 alteration : none)
	    [] [N O] then note (nom:{StringToAtom [N]}
	    			octave:{StringToInt [O]}
	    			alteration:none)
	    else silence
	    end
	 end
       end
      
      fun{NoteToEchantillon Note}
      	case Note
      	of silence then silence(duree:1.0)
      	[] note(nom:X octave:Y alteration:Z) then echantillon(hauteur:{ComputeDemiTons Note} duree:1.0 instrument:none)
        end
      end
      
      fun{Bourdon X Y}
        case Y of nil then nil
	[]H|T then 
	     case X of silence then silence(duree:H.duree)|{Bourdon X T}
	     [] note(nom:N octave:Octave alteration:A) then echantillon(hauteur:{ComputeDemiTons X} duree:H.duree instrument:H.instrument)|{Bourdon X T}
	     end
	end
      end
      
      fun{Muet X}
        {Bourdon silence X}
      end
      
      fun{Etirer X Y}
      	case Y of nil then nil
      	[]H|T then
            case H of silence(duree:D) then silence(duree:D*X)|{Etirer X T}
            []echantillon(hauteur:Z duree:Y instrument:I) then echantillon(hauteur:Z duree:Y*X instrument:I)|{Etirer X T}
            end
        end
      end
      
      fun{DureePart X Acc}
	case X of nil then Acc
	[]H|T then {DureePart T Acc+H.duree}
	end
      end
      
      fun{Duree X Y}
      	case Y of nil then nil
      	[]H|T then {Etirer X/{DureePart Y 0.0} Y}
      	end
      end
      
      fun{Transpose X Y}
      	case Y of nil then nil
      	[]H|T then
      	    case H of silence(duree:D) then silence(duree:D)|{Transpose X T}
      	    []echantillon(hauteur:H duree:Y instrument:I) then echantillon(hauteur:H+X duree:Y instrument:I)|{Transpose X T}
            end
        end
      end

      fun{ToVector Ech} % Transforme un echatillon en vecteur (ok)
	local
	  Long=44100.0*Ech.duree
	  Pi=3.141592
	  F
	  case Ech
	  of silence(duree:X) then F = 0
	  [] echantillon(hauteur:X duree:Y alteration:Z) then F=({Pow 2.0 X.hauteur/12.0}*440.0)
	  end
	  fun{Vector Acc}
	    if Acc=<Long then 0.5*{Sin ((2.0*Pi*F*Acc)/44100.0)}|{Vector Acc+1.0}
	    else
	      nil
	    end
	  end
	in
	  {Vector 1.0}
	end
      end

      fun{VoiceToVector L} % transforme une liste d'echantillon en vecteur audio
	case L
	of nil then nil
	[] H|T then
	  {Flatten {ToVector H}|{VoiceToVector T}}
	end
      end

      fun{ListVector X} % cree une liste contenant des listes representant les vecteurs audio a sommer
	case X
	of H|T then
	  case H
	  of N#M then {Ponderate N {Mix Interprete M}}|{ListVector T}
	end
      end

      fun{MergeToVector P}
      	local
      	M={ListToVector P}
      	fun{Somme X Acc}
            case X of nil then Acc
            []H|T then {Somme T {AddVector H Acc}}
            end
        end
        in
           {Somme M nil}
        end
      end

      fun{AddVector V1 V2}
         if V1\=nil andthen V2\=nil then V1.1+V2.1|{AddVector V1.2 V2.2}
         elseif V1==nil andthen V2\=nil then V2.1|{AddVector nil V2.2}
         elseif V2==nil andthen V1\=nil then V1.1|{AddVector V1.2 nil}
         else nil
         end
      end

      fun{Ponderate N M} % pondere un vecteur audio avec N
	case M
	of H|T then
	  N*H|{Ponderate N T}
	end
      end

      fun{Dispatcher X} % fonction qui choisit le filtre adapte
	 case X
	 of renverser(M) then {Renverser {Mix Interprete M}}
	 [] repetition (nombre:N M) then
	 [] repetition(duree:S M) then
	 [] clip(bas:F1 haut:F2 M) then {Clip F1 F2 {Mix Interprete M}}
	 [] echo(delai:S M) then
	 [] echo(delai:S decadence:F M) then
	 [] echo(delai:S decadence:F repetition:N M) then
	 [] fondu(ouverture:S1 fermeture:S2 M) then
	 [] fondu_enchaine(duree:S M1 M2) then
	 [] couper(debut:S1 fin:S2 M) then {Couper S1 S2 {Mix Interprete M}}
	 end
      end

      fun{Renverser M}
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
	case M of nil then nil
	[] H|T then
	  if H>F1 anthen H<F2 then H|{Clip F1 F2 T}
	  elseif H<F1 then F1|{Clip F1 F2 T}
	  elseif H>F2 then F2|{Clip F1 F2 T}
	  end
	end
      end

      fun{Couper S1 S2 M} % fonctionne que pour l'intervalle DANS le morceau
	local
	  Comp
	  fun{Aux S1 S2 M Comp}
	    if M==nil then nil
	    elseif Comp<S1*44100.0 then {Aux S1 S2 M.2 Comp+1.0}
	    elseif Comp>=S1*44100.0 andthen Comp<=S2*44100.0 then M.1|{Aux S1 S2 M.2 Comp+1.0}
	    elseif Comp>S2 then {Aux S1 S2 nil Comp}
	    end
	  end
	in
	  {Aux S1 S2 M 1}
	end
      end
   
   in
      % Mix prends une musique et doit retourner un vecteur audio.
      fun {Mix Interprete Music}
	 case Music
	 of nil then nil
	 []H|T then
	    case H
	    of voix(X) then {Flatten {VoiceToVector X}|{Mix Interprete T}}
	    []partition(P) then {Flatten {VoiceToVector {Interprete P}}|{Mix Interprete T}}
	    []wave(S) then {Flatten {Projet.readFile S}|{Mix Intreprete T}}
	    []merge(L) then {Flatten {MergeToVector L}|{Mix Interprete T}}
	    else {Flatten {Dispatcher H}|{Mix Interprete T}}
	    end
	 end
      end

      % Interprete doit interpréter une partition
      fun {Interprete Partition}
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
      Music = {Projet.load CWD#'joie.dj.oz'}
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
