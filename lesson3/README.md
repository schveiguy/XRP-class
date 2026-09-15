# Adding a Subsystem and Command

Let's add a subsystem and a command to the XRP project. For this, we will use
the rangefinder sensor, and then use that subsystem to implement a drive
command.

## The Rangefinder subsystem

The Rangefinder subsystem will be a thin wrapper around the XRPRangefinder type.
This type provides a direct mechanism to read the range from the hardware.

To add this subsystem, right click on the "subsystems" folder, and select
"Create a new class/command". Then select "Subsystem". Let's give the subsystem
the name Rangefinder.

A new file named Rangefinder.java should be added in the subsystems folder, with
the skeleton of a subsystem, as we discussed previously.

For now, the range subsystem has no real tasks to do, it's simply a holder for
the XRP hardware object, and provides a way to get the data.

### Add the rangefinder member

Add to the top of the class the following:

```java
  private final XRPRangefinder m_rangeFinder;
```

This tells the compiler we are going to store a member field called
`m_rangeFinder` with type `XRPRangefinder`. When you type in `XRPRangefinder`,
Visual Studio code will offer to import the module containing this class. Use
the Tab key to accept that, and the following import will be added to the top:

```java
import edu.wpi.first.wpilibj.xrp.XRPRangefinder;
```

If this doesn't happen, then just add that line manually.

But by default a member isn't initialized. We need to set it in the constructor.
Edit the default constructor to add the one line to initialize the rangefinder:

```java
  /** Creates a new Rangefinder. */
  public Rangefinder() {
    m_rangeFinder = new XRPRangefinder();
  }
```

### Accessor method

We will add a method that gets the current range between the XRP and the wall in
front of it. Let's call it `rangeInMeters`:

```java
  public double rangeInMeters() {
    return m_rangeFinder.getDistanceMeters();
  }
```

Note that the `public` is important here. Without that attribute, the function
would be inaccessible outside the package.

For now, we can leave the `periodic` function blank.

## DriveToWall command

Let's add a new command that drives the robot to within a given range of the
closest wall. The command will drive full-speed forward until it is within a
distance of the wall, and then full-stop.

Create a new command in the "commands" folder, by right clicking and select
"Create a new class/command". Select "Command", and give the name
`DriveToWall`.

The resulting file should contain all the basic elements of a new command. We
will need to edit the file to add all the functionality.

In order to drive, we need the `Drivetrain` subsystem. In order to read the
range, we need the `Rangefinder` subsystem. Our command needs to take both of
these in the constructor so it can use them as requirements. We also need a
*range* to tell it when to stop driving. This will be the target distance from
the wall.

```java
public class DriveToWall extends Command {
  private Rangefinder m_rangeFinder;
  private double m_metersDistance;
  private Drivetrain m_drivetrain;
  
  /** Creates a new DriveToWall. */
  public DriveToWall(double metersDistance, Rangefinder rangefinder,
       Drivetrain drive) {
    // Use addRequirements() here to declare subsystem dependencies.
    this.m_rangeFinder = rangefinder;
    this.m_metersDistance = metersDistance;
    this.m_drivetrain = drive;
    this.addRequirements(rangefinder, drive);
  }
```

Note that we named our distance `m_metersDistance`. Using a name for a variable
that gives immediate and definitive information about what is stored there will
help you in the future to remember what that variable is for.

### Command methods

Each method is quite straightforward. While the XRP is not within the distance
from the wall, it should drive forward.

For initialize, we normally would clear sensors, or maybe set up the
drivetrain. But our command is so simple, it doesn't need that step.

```java
// Called when the command is initially scheduled.
  @Override
  public void initialize() {}

  // Called every time the scheduler runs while the command is scheduled.
  @Override
  public void execute() {
    m_drivetrain.arcadeDrive(1, 0);
  }

  // Called once the command ends or is interrupted.
  @Override
  public void end(boolean interrupted) {
    m_drivetrain.arcadeDrive(0, 0);
  }

  // Returns true when the command should end.
  @Override
  public boolean isFinished() {
    return m_rangeFinder.rangeInMeters() <= m_metersDistance;
  }
```

Note `execute` just says "drive forward, full speed!". The first parameter
represents throttle forward and backwards, with 1 being full forward, and -1
being full backwards. The second parameter represents angular throttle, with 1
being full counter-clockwise and -1 being full clockwise. Because we aren't
turning, the second parameter is 0.

Once the command is over, we stop driving (implemented in `end`). This step is
important, a subsystem/motor will continue to run until you tell it not to.

And the `isFinished` method says to stop when the robot is within distance. Why
not use == here instead of <=? The reason is twofold. First, floating point
numbers very rarely are equal. Even when you want to compare two flaoting point
values for equality, you likely want to check that they are "close enough".
Second, we are measuring 50 times a second. Suppose there was a time where the
range would equal what we are looking for, we might miss it simply because we
didn't read the sensor at that specific moment!

Since the distance is always shrinking, we can just use a simple <= to decide
to stop.

## Add the Rangefinder subsystem to the robot container

In order to use the subsystem, we need to create an instance of it.

Where `RobotContainer` has member fields, add a new one for the range finder
subsystem:

```java
  private final Drivetrain m_drivetrain = new Drivetrain();
  private final XRPOnBoardIO m_onboardIO = new XRPOnBoardIO();
  private final Arm m_arm = new Arm();
  // add this line
  private final Rangefinder m_rangefinder = new Rangefinder();
```

## Bind the command to a button

For now, let's just take over the B button of your robot, commenting out the
original command (which sets the arm angle):

```java
    JoystickButton joystickBButton = new JoystickButton(m_controller, 2);
    // joystickBButton
    //     .onTrue(new InstantCommand(() -> m_arm.setAngle(90.0), m_arm))
    //     .onFalse(new InstantCommand(() -> m_arm.setAngle(0.0), m_arm));
    joystickBButton.onTrue(new DriveToWall(0.5, m_rangefinder, m_drivetrain));
```

Since the command self terminates, there is no reason to execute anything when
releasing the button.

What this does is drive until the robot is within 0.5m of the wall, and stop
the motors.

## Testing it out

If you wote everything correctly, the code should build and run. Running the
robot, move it so it is facing a wall, and press the B button on the controller
(if you are using the keyboard, this is the `x` key). The robot should dash
forward, and stop travelling forward once it is half a meter away.

But what happens? Does it stop on the spot? No! it continues to roll forward
until momentum has given way to friction.

This is because even though we stop driving the motors, we don't stop the
movement.

We will learn how to adjust our code in the next lesson.

# Exercise

Try adjusting the distance and see that your range finding code is properly
detecting the wall.

Instead of using `onTrue`, try `whileTrue`. What happens now when you release
the button early?

---

[Previous: Programming the XRP using WPILib](../lesson2/README.md)
