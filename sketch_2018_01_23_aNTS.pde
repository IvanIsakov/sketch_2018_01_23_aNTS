/*
Particles (ants) travel around randomly and leave the traces behind them (pheromones)


Copyright
Isakov Ivan
2018-02-22
*/

ArrayList<Ant> hive = new ArrayList<Ant>();
ArrayList<Ant> antsWithFood = new ArrayList<Ant>();
ArrayList<Food> couldron = new ArrayList<Food>();
ArrayList<Baloon> baloons = new ArrayList<Baloon>();
ArrayList<PVector> foodHome = new ArrayList<PVector>();
int arrayMaxSize = 100;
int antDim = 10;
int foodAtHome = 0;

void setup() {
  size(640,640);
//  fullScreen();
  for (int i = 0; i < 30; i++) {
    //PVector pveco = new PVector(width/2 + random(-50,50), height/2 + random(-50,50));
    PVector pveco = new PVector(width/2 - random(-100,100), height/2 - random(-100,100));
    Ant a = new Ant(pveco);
    a.velocity = PVector.random2D();
    a.velocity.mult(3);
    hive.add(a);
  }
 /*
  for (int j = 0; j < 100; j++) {
    PVector pveco = new PVector(width - random(100), random(100));
    Food f = new Food(pveco.x,pveco.y);
    couldron.add(f);
  }
  */
//  strokeWeight(5);
}

void draw() {
  background(255);
  //translate(width/4,height/4);
  for (Ant a : hive) {
    a.update();
    a.display();
  }
  
  for (Food f : couldron) {
    f.eatMe();
    f.display();
  }
  
  for (Baloon b : baloons) {
    b.update();
    b.display();
  }
  
  // Remove baloons that flew away
  for (int i = baloons.size()-1; i > -1; i--) {
    if (baloons.get(i).position.x > width + baloons.get(i).sizeB||
        baloons.get(i).position.x < 0 - baloons.get(i).sizeB||
        baloons.get(i).position.y > height + baloons.get(i).sizeB||
        baloons.get(i).position.y < 0 - baloons.get(i).sizeB) {
       baloons.remove(i);
        }
  }
  println(baloons.size());
  /*
  println(foodAtHome);
  for (PVector p : foodHome) {
    fill(255,0,0,100);
    ellipse(p.x,p.y,15,15);  
  }
  
  noFill();
  stroke(0);
  strokeWeight(1);
  rect(0,height - 50,50,50);
  */
  //saveFrame("video3/ants_explore-####.tiff");
}

class Ant {
  PVector position, velocity, acceleration;
  ArrayList<Float> arrayX1 = new ArrayList<Float>();
  ArrayList<Float> arrayY1 = new ArrayList<Float>();
  ArrayList<Float> odour = new ArrayList<Float>();
  boolean iHaveFood = true;
  color antColor;
  boolean bringHome = false;
  
  Ant(PVector PV) {
    position = PV;
    antColor = color(0,0,0);
  }
  
  void update() {
    PVector velocityDiv = PVector.mult(velocity, 0.5);
    position.add(velocityDiv);
    rememberWhereIwas(position); // Create pheromone trace
    PVector nos = new PVector(randomGaussian(),randomGaussian());
    velocity.add(nos.mult(0.1));  // add noise to the movement
    velocity.limit(5);
    
     // Bounce of the wall
    if (position.x >= width) {
      velocity.x = -velocity.x;
      position.x = width - 1;
      //position.x = 0;
    } else if (position.x <= 0) {
      velocity.x = -velocity.x;
      position.x = +1;
      //position.x = width;
    }
    if (position.y >= height) {
      velocity.y = -velocity.y;
      position.y = height - 1;
      //position.y = 0;
    } else if (position.y <= 0) {
      velocity.y = -velocity.y;
      position.y = 1;
      //position.y = width;
    }
    
    checkTrace();
    evadeCollision();
    //goHome();
  }
  
  void display() {
    drawPath();
    noFill();
    stroke(antColor);
    strokeWeight(antDim);
    //ellipse(position.x,position.y,antDim,antDim);
    line(position.x,position.y,position.x-velocity.x,position.y-velocity.y);
  }
  
  // Leave a pheromone trace by creating an array with previous position values
  void rememberWhereIwas(PVector newVector) {
    if (iHaveFood) {
      arrayX1.add(newVector.x);
      arrayY1.add(newVector.y);
      odour.add(1.0);
      int arraySiz = arrayX1.size();
      if (arraySiz > arrayMaxSize) {
        for (int i = 0; i < arraySiz - arrayMaxSize; i++) {
          arrayX1.remove(0);
          arrayY1.remove(0);
          odour.remove(0);
        }
      }
    } else {
      if (arrayX1.size() > 0) {
        arrayX1.remove(0);
        arrayY1.remove(0);
      }
    }
  }
  
  // Draw the trace
  void drawPath() {
//    println(arrayX1.size());
    
    strokeWeight(2);
    for (int i = 0; i < arrayX1.size() - 1; i++) {
      if (arrayX1.size() < arrayMaxSize) {
        stroke(255 - 255 * (i+1) / arrayX1.size(),255 - 127 * (i+1) / arrayX1.size(),255);
      } else {
        stroke(255 - 255*(i + 1)/arrayMaxSize,255 - 127*(i + 1)/arrayMaxSize,255);
      }
      line(arrayX1.get(i),arrayY1.get(i),arrayX1.get(i+1),arrayY1.get(i+1));
    }
  }
  // For food scavenging.
  void goHome() {
    PVector home = new PVector(0,height);
    PVector distanceFromHome = PVector.sub(home,position);
    if (iHaveFood) {
      
      velocity = PVector.mult(distanceFromHome,4/distanceFromHome.mag());
    }
    if (distanceFromHome.mag() < 50 && iHaveFood){
      iHaveFood = false;
      bringHome = true;
      antsWithFood.remove(this);
      foodAtHome++;
      PVector newFoodPos = new PVector(random(50), height - random(50));
      foodHome.add(newFoodPos);
    }
  }
  
  // Check others' traces, get attracted to them and follow them
  void checkTrace() {
    for (Ant a1 : hive) {
      if (a1 != this) {
        for (int i = 0; i < a1.arrayX1.size() - 5; i++) {
          PVector distance = PVector.sub(a1.position,position);
          if (distance.mag() > 2*antDim) {
            PVector distSniff = new PVector(a1.arrayX1.get(i) - position.x,a1.arrayY1.get(i) - position.y);
            if (distSniff.mag() < 10) {
              //antColor = color(0,255,255);
              if (distSniff.mag() > 2) {
              //velocity.add(distSniff.mult(0.01));          
              velocity.add(distSniff.mult(0.1/sq(distSniff.mag())));  
              // Check where the smell came from
              PVector distSniffNext = new PVector(a1.arrayX1.get(i+1) - position.x,a1.arrayY1.get(i+1) - position.y);  
              velocity.add(distSniffNext.mult(0.005));
              }
            } else {
              antColor = color(0,0,0);
            }
          }
        }
      }
    }
  }
  
  void evadeCollision() {
    for (Ant a1 : hive) {
      if (a1 != this) {
        PVector distance = PVector.sub(a1.position,position);
        if (distance.mag() < 3*antDim) {
          velocity.add(distance.mult((-1/sq(distance.mag()))));
          noFill();
          stroke(0,0,127);
          strokeWeight(1);
          ellipse(position.x,position.y,100*sqrt(distance.mag()),100*sqrt(distance.mag()));
          if (sqrt(distance.mag()) > 0.8) {
            Baloon b = new Baloon(position.x,position.y,50*sqrt(distance.mag()));
            baloons.add(b);
          }
        }
      }
    }
  }
}


class Food {
  PVector position = new PVector(0,0);
  boolean taken = false;
  Ant partner;

  Food(float x1, float y1) {
    position.x = x1;
    position.y = y1;
  }
  
  void eatMe() {
    if (!taken) {
      for (Ant a : hive) {
        PVector distan = PVector.sub(a.position,position);
        if (distan.mag() < antDim) {
          position = a.position;
          taken = true;
          a.iHaveFood = true;
          antsWithFood.add(a);
          partner = a;
        }
      }
    } else {
      if (partner.bringHome || !partner.iHaveFood) {
        position.x = -100;
        position.y = -100;
        partner.bringHome = false;
      } else if (partner.iHaveFood) {
        position = PVector.sub(partner.position, partner.velocity);
      }
    }
  }
  
  void display() {
    fill(255,0,0,127);
    noStroke();
    ellipse(position.x,position.y,15,15);
  }
  
}

// Baloons that are created when the ants are too close to each other
class Baloon {
  PVector position, velocity;
  float sizeB;
  
  Baloon(float x, float y, float sizeBol) {
    position = new PVector(x,y);
    //position.y = y;
    sizeB = sizeBol;
    velocity = new PVector(random(-1,1),random(-1,1));
  }
  
  void update() {
    position.add(velocity.mult(1));
  }
  
  void display() {
    //noFill();
    fill(0,127,255,50);
    noStroke();
    //strokeWeight(1);
    ellipse(position.x,position.y,sizeB,sizeB);
  }
}