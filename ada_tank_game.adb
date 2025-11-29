-------------------------------------------------------------------
--  TankGame - Artillery Game on Mountain Terrain
-------------------------------------------------------------------
--  Description : Simulates two tanks firing at each other
--                in a randomly generated mountain landscape.
--  Author      : Tobias Schurig
--  Date        : 10.04.2025
--  File        : Ada_Tank_Game.adb
-------------------------------------------------------------------

pragma Ada_2012;
with Ada.Text_IO;              use Ada.Text_IO;
with Ada.Float_Text_IO;        use Ada.Float_Text_IO;
with Ada.Numerics;             use Ada.Numerics;
with Ada.Numerics.Elementary_Functions;
with Ada.Numerics.Discrete_Random;
with Ada.Numerics.Float_Random;

procedure Ada_Tank_Game is

   Rows     : constant Integer   := 200;
   Cols     : constant Integer   := 238;
   Mountain : constant Character := '#';

   type GAMEFIELD_TA is array (1 .. Rows, 1 .. Cols) of Character;

   subtype Wind_Range is Integer range -5 .. 5;
   package Wind_Random is new Ada.Numerics.Discrete_Random(Wind_Range);
   Wind_Gen : Wind_Random.Generator;

   -- Arrows needed to display wind direction
   Arrow_length : constant Integer := 5;
   Arrow_right  : constant String  := String'(1 .. Arrow_length => '-') & ">";
   Arrow_left   : constant String  := "<" & String'(1 .. Arrow_length => '-');

   -- Wind indicator below the mountain range
   procedure Show_Wind_Below_Mountain(wind : Integer) is
      Windstr : String := Integer'Image(wind) & " m/s";
      Arrow   : String(1..(Arrow_length+1));
   begin
      Put_Line("Wind: " & Windstr);
      if wind > 0 then
         Arrow := Arrow_right(1..Arrow_length+1);
      elsif wind < 0 then
         Arrow := Arrow_left(1..Arrow_length+1);
      else
         Arrow := String'(1..Arrow_length+1 => '-');
      end if;
      Put_Line(Arrow);
      New_Line;
   end Show_Wind_Below_Mountain;

   -- Generate random mountain range
   -- The purpose of this function is to generate a randomized game field with
   -- mountains and terrain for gameplay use. It returns the gamefield as an
   -- array which contains the character "#" that indicates a solid
   function Generate_Field return GAMEFIELD_TA is
      Max_Height  : constant Integer := 40;
      Min_Height  : constant Integer := 5;
      Step_Chance : constant Float   := 0.02;
      Step_Size   : constant Integer := 2;
      Num_Peaks   : constant Integer := 3;

      Field       : GAMEFIELD_TA := (others => (others => ' '));

      type Height_Array is array (1 .. Cols) of Integer;
      Profile     : Height_Array;

      type Peak_Array is array (1 .. Num_Peaks) of Integer;
      Peak_Pos    : Peak_Array;
      Peak_Height : Peak_Array;

      package Rand renames Ada.Numerics.Float_Random;
      Gen : Ada.Numerics.Float_Random.Generator;

      Start_Col, End_Col, H, Delta1, Step : Integer := 0;
   begin
      Rand.Reset (Gen);

      for I in 1 .. Num_Peaks loop
         Peak_Pos (I) := Integer (Float (Cols) * (Float (I) / (Float (Num_Peaks) + 1.0)) +
                                  (Rand.Random (Gen) - 0.5) * Float (Cols) / (2.0 * Float (Num_Peaks)));
         if Peak_Pos (I) < 10 then
            Peak_Pos (I) := 10;
         elsif Peak_Pos (I) > Cols - 10 then
            Peak_Pos (I) := Cols - 10;
         end if;
         Peak_Height (I) := Min_Height + Integer (Rand.Random (Gen) * Float (Max_Height - Min_Height));
      end loop;

      for I in 1 .. Num_Peaks - 1 loop
         for J in I + 1 .. Num_Peaks loop
            if Peak_Pos (I) > Peak_Pos (J) then
               declare
                  Tmp_Pos    : Integer := Peak_Pos (I);
                  Tmp_Height : Integer := Peak_Height (I);
               begin
                  Peak_Pos (I) := Peak_Pos (J);
                  Peak_Height (I) := Peak_Height (J);
                  Peak_Pos (J) := Tmp_Pos;
                  Peak_Height (J) := Tmp_Height;
               end;
            end if;
         end loop;
      end loop;

      Start_Col := 1;
      for I in 1 .. Num_Peaks + 1 loop
         if I = 1 then
            End_Col := Peak_Pos (1);
            H := Peak_Height (1);
            for J in Start_Col .. End_Col loop
               Profile (J) := Min_Height + Integer (Float (H - Min_Height) * Float (J - Start_Col) / Float (End_Col - Start_Col + 1));
            end loop;
         elsif I = Num_Peaks + 1 then
            Start_Col := Peak_Pos (Num_Peaks);
            H := Peak_Height (Num_Peaks);
            for J in Start_Col .. Cols loop
               Profile (J) := H - Integer (Float (H - Min_Height) * Float (J - Start_Col) / Float (Cols - Start_Col + 1));
            end loop;
         else
            Start_Col := Peak_Pos (I - 1);
            End_Col := Peak_Pos (I);
            for J in Start_Col .. End_Col loop
               Profile (J) := Peak_Height (I - 1) + Integer (Float (Peak_Height (I) - Peak_Height (I - 1)) * Float (J - Start_Col) / Float (End_Col - Start_Col + 1));
            end loop;
         end if;
      end loop;

      for J in 2 .. Cols loop
         Delta1 := Integer (Rand.Random (Gen) * 3.0) - 1;
         if Rand.Random (Gen) < Step_Chance then
            if Rand.Random (Gen) < 0.5 then
               Step := Step_Size;
            else
               Step := -Step_Size;
            end if;
         else
            Step := 0;
         end if;
         H := Profile (J - 1) + Delta1 + Step;
         if H < Min_Height then
            H := Min_Height;
         elsif H > Max_Height then
            H := Max_Height;
         end if;
         if abs (H - Profile (J)) < 6 then
            Profile (J) := H;
         end if;
      end loop;

      declare
         Window       : constant Integer := 5;
         Half         : constant Integer := Window / 2;
         Temp_Profile : Height_Array := Profile;
         Sum          : Integer;
         Count        : Integer;
      begin
         for J in 1 .. Cols loop
            Sum := 0;
            Count := 0;
            for K in Integer'Max (1, J - Half) .. Integer'Min (Cols, J + Half) loop
               Sum := Sum + Temp_Profile (K);
               Count := Count + 1;
            end loop;
            Profile (J) := Sum / Count;
         end loop;
      end;

      for J in 1 .. Cols loop
         for I in (Rows - Profile (J) + 1) .. Rows loop
            Field (I, J) := Mountain;
         end loop;
      end loop;

      return Field;
   end Generate_Field;

   -- display mountain range
   procedure Display_Field (Field : in GAMEFIELD_TA) is
   begin
      for I in 1 .. Rows loop
         for J in 1 .. Cols loop
            Put (Field (I, J));
         end loop;
         New_Line;
      end loop;
   end Display_Field;

   subtype Left_Range  is Integer range 2 .. Cols / 3;
   subtype Right_Range is Integer range (2 * Cols / 3) .. (Cols - 1);

   package Rand_Left  is new Ada.Numerics.Discrete_Random(Left_Range);
   package Rand_Right is new Ada.Numerics.Discrete_Random(Right_Range);

   Gen_Left  : Rand_Left.Generator;
   Gen_Right : Rand_Right.Generator;

   type Profile_Array is array (1 .. Cols) of Integer;

   type Tank is record
      Col    : Integer   := 0;
      Symbol : Character := ' ';
   end record;


   -- The function "Determine_profile" determines the height of the mountain
   -- range from the bottom in each column and returns these values as a profile
   -- array. It is needed for the positioning of the tanks and to determine where
   -- a projectile hits the terrain
   function Determine_profile(SF : GAMEFIELD_TA) return Profile_Array is
      Result : Profile_Array;
   begin
      for J in 1 .. Cols loop
         Result(J) := 0;
         for I in 1 .. Rows loop
            if SF(I, J) = Mountain then
               Result(J) := Rows - I + 1;
               exit;
            end if;
         end loop;
      end loop;
      return Result;
   end Determine_profile;

   -- The function "Max_height_nearby_column" looks at each column in the gamefield
   -- and finds the first mountain block. It returns the maximal height from bottom
   -- to top for each column. It helps the game to place the tanks correctly.
   function Max_height_nearby_column(Profile : Profile_Array; Col : Integer) return Integer is
      Max_H : Integer := 0;
   begin
      for Offset in -1 .. 1 loop
         if Col + Offset in Profile'Range then
            if Profile(Col + Offset) > Max_H then
               Max_H := Profile(Col + Offset);
            end if;
         end if;
      end loop;
      return Max_H;
   end Max_height_nearby_column;

   -- The procedure "Place_tank" puts a tank on the gamefield at a given column
   -- by using the terrain profile to find the ground height. It places the tank's
   -- body character across three cells on the same height and the gun directly
   -- above the center cell.
   procedure Place_tank(
      SF      : in out GAMEFIELD_TA;
      Profile : in     Profile_Array;
      Col     : in     Integer;
      Body_C  : in     Character;
      Gun_C   : in     Character) is
      Max_H   : Integer := Max_height_nearby_column(Profile, Col);
      Ground  : Integer := Rows - Max_H + 1;
   begin
      for Offset in -1 .. 1 loop
         if Col + Offset in 1 .. Cols then
            SF(Ground, Col + Offset) := Body_C;
         end if;
      end loop;
      if Ground - 1 >= 1 then
         SF(Ground - 1, Col) := Gun_C;
      end if;
   end Place_tank;

   -- The function "tank in explosion radius" checks if a tank is within the range
   -- of an explosion by comparing the tank's position with an area around the
   -- explosion's center; if the tank is inside this radius, it is considered
   -- affected or damaged by the explosion. This helps the game decide which
   -- tanks take damage when an explosion happens.
   function Tank_in_explosion_radius(P : Tank; Profile : Profile_Array; X, Y, Radius : Integer) return Boolean is
      Max_H  : Integer := Max_height_nearby_column(Profile, P.Col);
      Ground : Integer := Rows - Max_H + 1;
      R2     : Integer := Radius * Radius;
   begin
      for Offset in -1 .. 1 loop
         if P.Col + Offset in Profile'Range then
            if ( (Ground - Y)*(Ground - Y) + (P.Col + Offset - X)*(P.Col + Offset - X) ) <= R2 then
               return True;
            end if;
         end if;
      end loop;
      if (Ground - 1 >= 1) then
         if ( (Ground - 1 - Y)*(Ground - 1 - Y) + (P.Col - X)*(P.Col - X) ) <= R2 then
            return True;
         end if;
      end if;
      return False;
   end Tank_in_explosion_radius;


   -- The procedure "Crater" creates a crater on the game field by removing mountain
   -- blocks within a specified radius around a given explosion point. It is modifying
   -- the terrain to simulate damage from an explosion.
   procedure Crater(SF : in out GAMEFIELD_TA; X, Y, Radius : Integer) is
      R2 : constant Integer := Radius * Radius;
   begin
      for I in Integer'Max(1, Y - Radius) .. Integer'Min(Rows, Y + Radius) loop
         for J in Integer'Max(1, X - Radius) .. Integer'Min(Cols, X + Radius) loop
            if (I - Y) * (I - Y) + (J - X) * (J - X) <= R2 then
               if SF(I, J) = Mountain then
                  SF(I, J) := ' ';
               end if;
            end if;
         end loop;
      end loop;
   end Crater;

   -- The procedure "Clear_Trajectory" clears or removes the projectile's trajectory
   -- path from the game field by deleting any temporary marks or characters that
   -- show the flight path, so the game field is clean again for the next move or shot.
   procedure Clear_Trajectory(SF : in out GAMEFIELD_TA) is
   begin
      for I in 1 .. Rows loop
         for J in 1 .. Cols loop
            if SF(I, J) = '.' then
               SF(I, J) := ' ';
            end if;
         end loop;
      end loop;
   end Clear_Trajectory;


   -- The function "Shot" simulates shooting a projectile in the game by calculating
   -- its position step-by-step over time, taking into account the initial angle,
   -- power, gravity and wind, updating the projectile's location until it hits
   -- the ground or an obstacle, and then processing the impact (like creating an
   -- explosion or damaging tanks) accordingly. Indicated by a line of dots.
   function Shot(
      SF       : in out GAMEFIELD_TA;
      Profile  : in     Profile_Array;
      Start_X  : Integer := 0;
      Start_Y  : Integer := 0;
      Angle    : Float   := 0.0;
      Power    : Float   := 0.0;
      Wind     : Integer := 0;
      Enemy    : Tank;
      Own      : Tank;
      Tank_hit : out Character) return Boolean is

      G         : constant Float   := 9.81;
      T         :          Float   := 0.0;
      Delta_T   : constant Float   := 0.05;
      V0x, V0y  :          Float   := 0.0;
      X, Y      :          Float   := 0.0;
      Hit       :          Boolean := False;
      Max_Steps : constant Integer := 2000;
      Step      :          Integer := 0;
      Radius    : constant Integer := 4;
      Direction :          Integer := 1;
      Wind_F    : constant Float   := Float(Wind);
   begin
      Tank_hit := ' ';
      if Own.Symbol = 'T' then
         Direction := -1;
      else
         Direction := 1;
      end if;

      V0x := Float(Direction) * Power * Ada.Numerics.Elementary_Functions.Cos(Angle * 3.141592 / 180.0);
      V0y := Power * Ada.Numerics.Elementary_Functions.Sin(Angle * 3.141592 / 180.0);

      X := Float(Start_X);
      Y := Float(Start_Y);

      loop
         Step := Step + 1;
         X := Float(Start_X) + V0x * T + 0.5 * Wind_F * T * T;
         Y := Float(Start_Y) - V0y * T + 0.5 * G * T * T;

         if Integer(X) in 1 .. Cols and Integer(Y) in 1 .. Rows then
            if SF(Integer(Y), Integer(X)) = ' ' then
               SF(Integer(Y), Integer(X)) := '.';
            end if;
         end if;

         if Integer(X) < 1 or Integer(X) > Cols or Integer(Y) < 1 or Integer(Y) > Rows then
            exit;
         end if;

         if SF(Integer(Y), Integer(X)) = Mountain then
            Crater(SF, Integer(X), Integer(Y), Radius);
            if Tank_in_explosion_radius(Enemy, Profile, Integer(X), Integer(Y), Radius) then
               Tank_hit := Enemy.Symbol;
               Hit := True;
            elsif Tank_in_explosion_radius(Own, Profile, Integer(X), Integer(Y), Radius) then
               Tank_hit := Own.Symbol;
               Hit := True;
            end if;
            exit;
         end if;

         T := T + Delta_T;
         if Step > Max_Steps then
            exit;
         end if;
      end loop;

      return Hit;
   end Shot;

   -- The function Game controls the whole match: it sets up the battlefield and
   -- tanks, then runs the main loop where players take turns aiming and shooting
   -- until one tank is destroyed and the game ends.
   procedure Game is
      Gamefield_Obj    : GAMEFIELD_TA;
      Profile          : Profile_Array;
      Current_Player   : Tank;
      Enemy            : Tank;
      S_Tank           : Tank;
      T_Tank           : Tank;
      Start_X, Start_Y : Integer        := 0;
      Angle            : Float          := 0.0;
      Power            : Float          := 0.0;
      Won              : Boolean        := False;
      Round            : Integer        := 0;
      Max_H            : Integer        := 0;
      Tank_hit         : Character      := ' ';
      Wind             : Integer        := 0;
      Wind_Change_Prob : constant Float := 0.3;
      Rand_Float       : Ada.Numerics.Float_Random.Generator;
   begin
      Rand_Left.Reset(Gen_Left);
      Rand_Right.Reset(Gen_Right);
      Wind_Random.Reset(Wind_Gen);
      Ada.Numerics.Float_Random.Reset(Rand_Float);

      loop
         Wind := Wind_Random.Random(Wind_Gen);
         exit when Wind /= 0;
      end loop;

      loop
         S_Tank.Col := Rand_Left.Random(Gen_Left);
         T_Tank.Col := Rand_Right.Random(Gen_Right);
         exit when T_Tank.Col - S_Tank.Col >= 10;
      end loop;
      S_Tank.Symbol := 'S';
      T_Tank.Symbol := 'T';

      Gamefield_Obj := Generate_Field;
      Profile := Determine_profile(Gamefield_Obj);

      Place_tank(Gamefield_Obj, Profile, S_Tank.Col, 'S', 'S');
      Place_tank(Gamefield_Obj, Profile, T_Tank.Col, 'T', 'T');

      loop
         Round := Round + 1;

         Display_Field(Gamefield_Obj);

         Show_Wind_Below_Mountain(Wind);

         if Round mod 2 = 1 then
            Current_Player := S_Tank;
            Enemy := T_Tank;
         else
            Current_Player := T_Tank;
            Enemy := S_Tank;
         end if;

         Profile := Determine_profile(Gamefield_Obj);
         Max_H := Max_height_nearby_column(Profile, Current_Player.Col);
         Start_Y := Rows - Max_H;
         Start_X := Current_Player.Col;

         Clear_Trajectory(Gamefield_Obj);

         loop
            begin
               Put("Player "); Put(Current_Player.Symbol); Put_Line(", your Turn!");
               Put("Type in Angle (degree) (e.g. 10 - 80): ");
               Get(Angle);
               exit;
            exception
               when others =>
                  Put_Line("Invalid input for Angle. Please try again.");
                  Skip_Line;
            end;
         end loop;

         loop
            begin
               Put("Type in Power (e.g. 10 - 60): ");
               Get(Power);
               exit;
            exception
               when others =>
                  Put_Line("Invalid input for Power. Please try again.");
                  Skip_Line;
            end;
         end loop;

         Won := Shot(Gamefield_Obj, Profile, Start_X, Start_Y, Angle, Power, Wind, Enemy, Current_Player, Tank_hit);

         Put_Line("Trajectory and Result:");
         Display_Field(Gamefield_Obj);

         if Ada.Numerics.Float_Random.Random(Rand_Float) < Wind_Change_Prob then
            loop
               Wind := Wind_Random.Random(Wind_Gen);
               exit when Wind /= 0;
            end loop;
         end if;

         if Tank_hit = Enemy.Symbol then
            case Enemy.Symbol is
               when 'S' =>
Put_Line(" ____  _                         ____                        _ ");
Put_Line("|  _ \| | __ _ _   _  ___ _ __  / ___|  __      _____  _ __ | |");
Put_Line("| |_) | |/ _` | | | |/ _ \ '__| \___ \  \ \ /\ / / _ \| '_ \| |");
Put_Line("|  __/| | (_| | |_| |  __/ |     ___) |  \ V  V / (_) | | | |_|");
Put_Line("|_|   |_|\__,_|\__, |\___|_|    |____/    \_/\_/ \___/|_| |_(_)");
Put_Line("               |___/                                           ");
               exit;
               when 'T' =>
Put_Line(" ____  _                         _____                       _ ");
Put_Line("|  _ \| | __ _ _   _  ___ _ __  |_   _| __      _____  _ __ | |");
Put_Line("| |_) | |/ _` | | | |/ _ \ '__|   | |   \ \ /\ / / _ \| '_ \| |");
Put_Line("|  __/| | (_| | |_| |  __/ |      | |    \ V  V / (_) | | | |_|");
Put_Line("|_|   |_|\__,_|\__, |\___|_|      |_|     \_/\_/ \___/|_| |_(_)");
Put_Line("               |___/                                           ");
               exit;
               when others => null;
            end case;
         end if;
      end loop;
   end Game;

begin
New_Line(15);
Put_Line("                                                                          __        __   _                            _                               ");
Put_Line("                                                                          \ \      / /__| | ___ ___  _ __ ___   ___  | |_ ___    _ __ ___  _   _      ");
Put_Line("                                                                           \ \ /\ / / _ \ |/ __/ _ \| '_ ` _ \ / _ \ | __/ _ \  | '_ ` _ \| | | |     ");
Put_Line("                                                                            \ V  V /  __/ | (_| (_) | | | | | |  __/ | || (_) | | | | | | | |_| |     ");
Put_Line("                                                                             \_/\_/ \___|_|\___\___/|_| |_| |_|\___|  \__\___/  |_| |_| |_|\__, |     ");
Put_Line("                                                                                                                                           |___/      ");
Put_Line("                                                                          _       _         _____           _               ____                      ");
Put_Line("                                                                         / \   __| | __ _  |_   _|_ _ _ __ | | __          / ___| __ _ _ __ ___   ___ ");
Put_Line("                                                                        / _ \ / _` |/ _` |   | |/ _` | '_ \| |/ /  _____  | |  _ / _` | '_ ` _ \ / _ \");
Put_Line("                                                                       / ___ \ (_| | (_| |   | | (_| | | | |   <  |_____| | |_| | (_| | | | | | |  __/");
Put_Line("                                                                      /_/   \_\__,_|\__,_|   |_|\__,_|_| |_|_|\_\          \____|\__,_|_| |_| |_|\___|");
Put_Line("");
Put_Line("");
	Put ("                                                                                                        Press Enter to start");
	Skip_Line;
   Game;
end Ada_Tank_Game;
