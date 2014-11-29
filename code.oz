% Vous ne pouvez pas utiliser le mot-clé 'declare'.
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
      	local
      	  Error1
      	  Error2
      	  DiffOctave = Note.octave - 4   % 4 est l'octave fondamentale
      	  NoteString = {AtomToString Note.nom}
      	  Ref = {AtomToString 'a'}
      	  DiffNote = 2*(NoteString - Ref)   % supposons deux demi-tons entre chaque note
      	in
      	  if NoteString>98 then Error1 = 1
      	  elseif NoteString>101 then Error2 = 2
      	  else Error1=0
      	  end
      	  if Note.alteration=='#' then Error2=1
      	  else Error2=0
      	  end
      	12*DiffOctave+DiffNote+Erroe1+Error2
      	end
      end  %ne fonctionne pas j'y travaille
      
      fun { ToNote Note }
         case Note
	 of Nom#Octave then note (nom:Nom octave:Octave alteration :'#')
	 [] Atom then
	    case { AtomToString Atom }
	    of [N] then note ( nom : Atom octave : 4 alteration : none )
	    [] [N O] then note (nom :{ StringToAtom [N]}
	    			octave :{ StringToInt [O]}
	    			alteration : none )
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
	     [] note(nom:N octave:Octave alteration:A then echantillon(hauteur:{ComputeDemiTons X} duree:H.duree instrument:H.instrument)|{Bourdon X T}
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
   
   in
      % Mix prends une musique et doit retourner un vecteur audio.
      fun {Mix Interprete Music}
         Audio
      end

      % Interprete doit interpréter une partition
      fun {Interprete Partition}
      	case Partition of nil then nil
      	[]H|T then
            case H of muet(X) then {Muet {Interprete {Flatten X}}}|{Interprete T}
            [] duree(secondes:X Y) then {Duree X {Interprete {Flatten Y}}}|{Interprete T}
            [] etirer(facteur:X Y) then {Etirer X {Interprete {Flatten Y}}}|{Interprete T}
            [] bourdon(note:X Y) then {Bourdon {ToNote X} {Interprete {Flatten Y}}}|{Interprete T}
            [] transpose( demitons:X Y ) then {Transpose X {Interprete {Flatten Y}}}|{Interprete T}
            []A then {NoteToEchantillon {ToNote A}}|{Interprete T}
            end
        end
      end  %manque le flatten du tout début

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
