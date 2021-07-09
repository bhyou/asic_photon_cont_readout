/*************************************************************************
 > Copyright (C) 2021 Sangfor Ltd. All rights reserved.
 > File Name   : sensor.svh
 > Author      : bhyou
 > Mail        : bhyou@foxmail.com 
 > Created Time: Wed 07 Jul 2021 07:15:52 PM CST
 ************************************************************************/

//----------------------------------------------------------------
// a front-end of sensor is descripted in the sensor class. once a photon is coming, 
// the get_collected_energy task in sensor class returns the energy collected by the 
// current pixel.
// 
// principle:
// 1. the area where energy is dposited in the pixel array is regarded as a circle.
// 2. the area where the charge is collected by the front-end of pixel is also regarded as a circle.
// 3. the intersecting area of the two circle( it is principle 1 and 2) is regarded as the value of 
//     charge or energy actually collected.
//----------------------------------------------------------------
 `include "photon.sv"

class sensor;
   mailbox  mbx;
   int      localCoorX;
   int      localCoorY;
   event    sensorDone;
   real     pi = 3.1415926;

   function new(int coorX, coorY, mailbox mbx);
      this.localCoorX = coorX;
      this.localCoorY = coorY;
      this.mbx        = mbx;
   endfunction 

   task automatic get_collected_energy(output real result);
      photon    drvTrns   ;
      int       hitCoorX  ;
      int       hitCoorY  ; 
      int       hitEnergy ;

      real      radiusCC ;  // the radius of charge collected
      real      radiusED ;  // the radius of energy deposition
      real      hit2pixDist; // the distance from hit position to charge collection pixel
      real      angleCC ;
      real      angleED ;
      real      fanAreaCC;
      real      fanAreaED; 
      real      quadArea ;

      mbx.get(drvTrns);   // receive hit event 
      hitCoorX  = drvTrns.addrX;
      hitCoorY  = drvTrns.addrY;
      hitEnergy = drvTrns.energy;
      
      radiusCC = `CollectRadius;
      radiusED = get_deposition_radius(hitEnergy); 
      hit2pixDist = $hypot((hitCoorX-localCoorX),(hitCoorY-localCoorY));

      if(hit2pixDist < radiusCC + radiusED) begin
         if(hit2pixDist > get_absolute_diferentce(radiusCC, radiusED))  begin 
         angleCC = get_angle(radiusCC, radiusED, hit2pixDist);
         angleED = get_angle(radiusED, radiusCC, hit2pixDist);

         fanAreaCC = get_fan_aera(radiusCC, angleCC);
         fanAreaED = get_fan_aera(radiusED, angleED);   // get the aera of fan-shape 2
         quadArea = radiusCC * hit2pixDist * $sin(angleCC);   // get the Area of Quadrilateral

         result = fanAreaCC + fanAreaED - quadArea;
         end
         else begin
            if(radiusED > radiusCC)  result = pi * radiusCC * radiusCC;
            else                     result = pi * radiusED * radiusED;
         end
      end
      else begin
         result = 0;
      end

      if(`DEBUG_MEDIUM) begin
         $display("@%0t the distance from hit position to current pixel is %f", $time, hit2pixDist);
         $display("@%0t the radius of energy deposition is %f", $time, radiusED);
         $display("@%0t the angle of colected energy is %f", $time, angleCC);
         $display("@%0t the angle of deposition energy is %f", $time, angleED);
         $display("@%0t the area of colected energy is %f", $time, fanAreaCC);
         $display("@%0t the area of deposition energy is %f", $time, fanAreaED);
         $display("@%0t the area of Quadrilateral is %f", $time, quadArea);
         $display("@%0t collected energy is %f", $time, result);
         $display("-------------------------------------------------\n");
      end
   endtask

   task automatic convert_energy_to_voltage(output real voltage);
      real   energy;
      get_collected_energy(energy);
      voltage = (energy / (pi * $pow(`CollectRadius, 2))) * 100;
      -> sensorDone;
   endtask

   function real get_deposition_radius(input int energy);
      if(energy<=250)  return energy/5;
      else             return 50;
   endfunction

   function real get_angle(real r1, r2, distan);
      real numerator, denominator; 
      numerator = r1 * r1 + distan * distan - r2 * r2;  // innverse triangular numerator
      denominator = 2 * r1 * distan; // inverse triangular denominator
      return $acos(numerator/denominator);
   endfunction

   function real get_fan_aera(real radius, real angles);
      return  radius * radius * angles;
   endfunction

   function real get_absolute_diferentce(real inx, iny);
      if(inx < iny)   return iny - inx;
      else            return inx - iny;
   endfunction

endclass 
`ifdef testingSensor
program testcase();
   generator  Gen;
   sensor     sensor;
   mailbox    mbx;
   event      done;
   real       energy;

   initial begin
      mbx     = new();
      Gen     = new(mbx);
      sensor     = new(25,25);
      sensor.mbx = mbx;
      Gen.drvDone = done;
      sensor.sensorDone = done;
      Gen.hitsNumber = 5;
      fork
         Gen.genData(); 
         forever sensor.get_collected_energy(energy);         
      join_any
   end

endprogram

`endif