import processing.svg.*;

boolean record = false;

void setup() {
  // Set size to dimensions of paper - 8x10.
  size(960, 768, P3D);
  colorMode(HSB, 360, 100, 100, 100);
  smooth(8);
}

void draw() {
  // If record flag is set, set up the SVG output.
  if (record) {
    beginRaw(SVG, "output.svg");
    hint(ENABLE_DEPTH_SORT);
    
    // Use white background / black default stroke when saving to SVG.
    background(0, 0, 100);
    stroke(0, 0, 0);
  } else {
    background(0, 0, 0);
    stroke(0, 0, 100);
  }
  
  //println(mouseX, mouseY);
  strokeWeight(1);
  noFill();
  
  // Radius of circle in center. Lines radiating outwards
  // will start from this distance from center and end at
  // edge of canvas.
  float radius = 125;
  
  // Translate to middle of canvas to make it easy to draw each line.
  translate(width / 2, height / 2);
  
  // Draw the circle in the center of the canvas.
  circle(0, 0, radius * 2);
  
  // This is the number of lines to draw around the circle. 
  float steps = 120;
  
  // Draw each line.
  for (int i = 0; i < steps; i++) {
    // Red at bottom
    if (i < 10) {
      stroke(0, 100, 100);
    // Copper to either side of red
    } else if (i < 17 || i > steps - 10) {
      stroke(16, 61, 100);
    // Gold for everything else
    } else {
      stroke(40, 64, 100);
    }
    
    // Calculate the number of degrees to rotate for this
    // specific step. 360/steps gets us the number of degrees
    // per step (since we're not doing 360 - i.e. if we had 180
    // steps, we would need to move 2 degrees for each step, not 1)
    // Multiplying this value by i gives us the total rotation.
    int degree = floor(i * (360 / steps));
    
    // If you uncomment this, the lines will be rainbow colored.
    //stroke(degree, 100, 100);
    
    pushMatrix();
    
    // Rotate by `degrees` degrees. This makes it way easier
    // to draw the lines because we don't have to calculate the
    // position of each point in model space, we just have to
    // calculate the position relative to a straight line that
    // is in the same position every time and the matrix
    // transformations handle the positioning.
    rotateZ(radians(degree));
    
    // Move outwards from the center point by `radius` pixels.
    translate(0, radius, 0);
    
    // j will be the y position in pixels.
    float j = 0;
    
    // Every time we start a new line, always start
    // by drawing a segment instead of a break.
    boolean draw = true;
    
    // Initialize these values.
    // break_remaining = the number of pixels left until we start drawing again
    // draw_remaining = the number of pixels left until we stop drawing
    int break_remaining = 0;
    float draw_remaining = draw_distance(j, i);
    
    // Each line segment is a PShape formed from vertexes.
    // Normally beginShape is called when the break ends (see below)
    // but we need to call it before starting anything since that
    // code will not have been executed yet.
    beginShape();
    
    // Start at 0 = radius and keep going until we reach the widest dimension.
    // I used `max` here because it allows the code to automatically adapt
    // to any dimensions.
    while (j < max(width, height)) {
      j += 1;
      
      // If we're drawing, do some drawing.
      if (draw) {
        // Decrement the number of pixels remaining to be drawn.
        draw_remaining -= 1;
        
        // Calculate the x value. If this was always 0, the line
        // would be straight; by converting j to radians and
        // getting the sin, this causes a waving motion back
        // and forth. The map value is hardcoded because of the
        // way that I experiment. Originally, this code was:
        // 
        // map(mouseY, 0, height, 1, 5)
        //
        // This allows me to see the output from a range of
        // different values by just moving my mouse cursor
        // up and down on the canvas. The commented code above
        // that outputs the mouseX/mouseY then allows me to see
        // what the mapped value is so that I can paste it
        // in here to replace the `mouseY` in the segment above.
        // I also hardcode the height because sometimes I change
        // the dimensions - if I just used `height` like I do
        // above, when the dimensions are changed, the value below
        // would also no longer match what I found and liked.
        // 
        // Since `sin` returns a value between -1 and 1, I multiply
        // the sin value by a constant (75 in this case). This means
        // that the line can wave back and forth by 150 pixels
        // (from -75 to +75).
        float x = sin(radians(j * map(j, 0, 793, 1, map(60, 0, 793, 1, 5)))) * 75;
        
        // Draw a vertex in the shape. I check if j is an exactly divisible
        // by an integer that ranges from 1-10 depending on how far j is
        // from the center. This limits the number of points that
        // get recorded in the SVG. This doesn't change the _shape_
        // of the outputted line, it just reduces the resolution.
        // This reduces file size (important for plotting) and
        // also reduces the plotting time.
        // 
        // In this case, the modulus is also a mapped value.
        // When j is closer to 0 (in this case, this is the radius,
        // since we translate to [0, `radius`] above) this means
        // that there will be more points resolution; when it's closer
        // to any edge, there are fewer points.
        if (j % floor(map(j, 0, width, 1, 10)) == 0) {
          vertex(x, j);
        }
        
        // In the code below, I'm going to avoid outputting
        // unnecessary points, i.e., points that fall outside of
        // the boundaries of the sheet of paper I'll be plotting
        // on. In order to do this, I need to know whether the absolute
        // point (relative to the dimensions of the canvas) is outside
        // of the boundary. The thing is, if I just use x or j (the
        // points of the vertex above) this won't work, since these values
        // are relative to the rotation/translation transformations
        // that were applied above. modelX and modelY accept (x, y, z)
        // coordinates and return the absolution position, i.e., without
        // transformations applied.
        float mx = modelX(x, j, 0);
        float my = modelY(x, j, 0);
        
        // If there are no more points left in the drawing, or if
        // we're outside of the boundaries of the canvas, set a new break
        // distance and close the shape object so that the line ends.
        if (draw_remaining < 0 || mx < 0 || my < 0 || mx > width || my > height) {
          break_remaining = break_distance(j, i);
          draw = !draw;
          endShape();
        }
      // If we're not drawing, don't draw.
      } else {
        // We basically just count down until we can start drawing again.
        break_remaining -= 1;
        
        // We're ready to start drawing again - get a new
        // drawing distance and start a new PShape object (line).
        if (break_remaining < 0) {
          draw_remaining = draw_distance(j, i);
          draw = !draw;
          beginShape();
        }
      }
    }
    
    popMatrix();
  }
  
  // If record flag is set, unset it and save output.
  if (record) {
    endRaw();
    record = false;
  }
}

// I originally had this code returning arbitrary
// distances but I didn't like the appearance, so
// it just returns 5 every time. Uncomment lines 1/2
// or 3/4 to see what I saw and didn't like.
int break_distance(float j, int s) {
  //int max_break = ceil(noise(0, 1) * 50);
  //return max_break - abs(ceil(map(sin(radians(j * map(j, 0, height, 1, 3))) * 75, -75, 75, -max_break, max_break)));
  //int max_break = 5;
  //return max_break - abs(ceil(map(sin(radians(j * map(j, 0, height, 1, 3))) * 75, -75, 75, -max_break, max_break)));
  return 5;
}

// Returns the length of the line that should be drawn,
// depending on which line we're drawing (s) and how far 
// from the center we're starting (j).
float draw_distance(float j, int s) {
  //return ceil(min(50, max(1, noise(j) * (width / 10))));
  //float maxval = map(mouseX, 0, width, 0.1, 20);
  //println(maxval);
  
  // I used the code above to find the maximum value
  // 9.979055 below. mapval is a divisor for the
  // step number (rotation around the circle) that
  // we're drawing.
  //
  // This is another case where I followed the pattern of
  // experimenting using `map` with `mouseX` to find 
  // a value I liked and then hardcoded it. Change
  // 101 to `mouseX` and run to play around with it.
  float mapval = map(101, 0, 1122, 0.1, 9.979055);
  
  // The distance will be the number of the step
  // we're on (0-120) divided by the mapping value
  // from above. Since mapval is actually a constant
  // value (we're not dynamically changing anything
  // in the map, just using it to calculate a very
  // precise value this has the effect of producing
  // the "spiral" shape of the drawing, since each
  // progressive step's line segments are slightly
  // longer than the previous step's line segments.
  return s / mapval;
}


// If the mouse is clicked, store an SVG.
void mouseClicked() {
  record = true;
}
