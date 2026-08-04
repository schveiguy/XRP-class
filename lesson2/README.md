# XRP example

Before we add our first code, let's take a few looks at how an FRC program,
based on the XRP example, works. First to note is that even though this is a
simulation-based program for a little XRP robot, actual FRC robots have the same
structure.

## Subsystem

What is a subsystem? it is a logical collection of hardware devices that work
together to implement a part of your robot. In FRC, a component of hardware is
represented by a class. Generally from a vendor such as CTRE or Rev.

These objects represent a physical piece of hardware, such as a motor, or a
sensor. The methods of these objects allow you to set outputs on these devices
or read inputs from those devices.

A subsystem's job should be to operate the hardware components in a way that
effectively operates the robot as a whole. For example, a drive subsystem might
contain 4 motors, and it should run these motors in a way to properly steer and
move the robot. When you build a Drive subsystem, you don't tell it which motors
to run at what speeds, you tell it to drive or turn at a specified speed, and it
knows how to run the individual motors to make that happen.

### XRP Drivetrain Subsystem

If you look at the `Drivetrain` class in the XRP example code, you can see that
it contains two ` XRPMotor` objects representing the two wheel motors, and two
`Encoder` objects representing the wheel encoders.

There is a helper object in here as well, a `DifferentialDrive` object. This is
a standard WPILib object which knows how to drive a robot given two "setter"
functions from motors. This object actually drives the motors based on the
configuration you give it.

There are many such helper types in WPILib. It is always good to utilize the
helper classes, as these have been developed and tested over many years, and
contain very few bugs if any.

Finally, the drive subsystem contains an `XRPGyro` object representing the IMU
unit. Although the gyro is not used to actually run the driving of the wheels,
it makes sense to hold it here, as the gyro can be used to determine
orientiation of the robot - a key part of driving. We will see the importance of
this later.

The constructor for the `Drivetrain` subsystem configures the motors, the
DifferentialDrive, and the IMU. All of the methods pertain to driving,
configuring, setting, and reading, the hardware components of the drive system.

### Arm subsystem

The `Arm` subsystem is even simpler. This subsystem contains a single
`XRPServo` object, and one interesting method, the `setAngle` method, which
tells the servo to go to a specific angle.

A subsystem doesn't need to be complex or large. It can contain one item like
the `Arm`, or many items that work together like `Drivetrain`. The important
thing to think about is how you want to model the components of your robot.

## RobotContainer

Recall in Java that the entry point for your program is `public static void
main`. However, in FRC robot code the framework is in charge of the start of the
program. Your code is initialized using your `RobotContainer` class.

The `RobotContainer` class should hold all your subsystems, controllers, and any
other items you want to keep track of. There will be only one `RobotContainer`
allocated by the system, and you should initialize everything in the
constructor, or using field initializers.[^1]

[^1]: Field initializers actually are run on construction, and so they are
    effectively part of the constructor.

Let's take a look at the XRP default field initializers and the constructor:

```java
  // The robot's subsystems and commands are defined here...
  private final Drivetrain m_drivetrain = new Drivetrain();
  private final XRPOnBoardIO m_onboardIO = new XRPOnBoardIO();
  private final Arm m_arm = new Arm();

  // Assumes a gamepad plugged into channel 0
  private final Joystick m_controller = new Joystick(0);

  // Create SmartDashboard chooser for autonomous routines
  private final SendableChooser<Command> m_chooser = new SendableChooser<>();

  /** The container for the robot. Contains subsystems, OI devices, and commands. */
  public RobotContainer() {
    // Configure the button bindings
    configureButtonBindings();
  }
```

We can see the subsystems for `Drivetrain` and `Arm` are created using
initializers. What is the `XRPOnBoardIO`? This is actually a hardware object,
and is not wrapped in a subsystem. It is not recommended to model any hardware
this way, but the default program does do this, so we'll leave it for now. The
hardware object provides inputs and outputs for the various IO ports on the XRP
(such as the user button and the green LED).

The controler is initialized using the `Joystick` object. This is a generic object
which could be any controller with a joystick and some buttons. WPILib knows how
to talk to a lot of different types of controllers, so this handles the input no
matter what type of controller you connect. If you want access to more specific
features of a controller, you need to instantiate that specific controller
instead.

Then there is a `SendableChooser<Command>` object. This is an object
which connects a variable to a SmartDashboard item. Using a tool like Elastic,
we can actually give a user-interface to the robot, which allows you to select
an auto to run. You may notice an interesting syntax here, the angle brackets.
This is called a "Generic" class, where you can tell the class the type of thing
you are sending (in this instance, you are sending a `Command` object).

Inside the actual constructor, we call the method `configureButtonBindings`.
This establishes all the commands to perform when certain buttons are pressed or
joysticks are used. We'll get to that in a moment.

## Commands

As mentioned in lesson 1, a *Command* is an object which implements a behavior
for the robot using the subsystems. It is generally attached to an Event trigger
such as a button or timer.

The XRP example project contains many commands, some of which are used in the
example `configureButtonBindings` function.

It is important to note that a command object is created on *initialization*,
not when the event occurs. When the command is finished, it does not get
removed, it keeps waiting for an event to occur that will run it.

There are 3 phases to the command:

1. Inactive - When no event has triggered a command, it is created but not
   executing.
2. Initializing - When a command gets triggered, it initializes. and gets ready
   to execute
3. Executing - While a command is active, the command can perform tasks every
   event loop. It might complete its task and mark itself inactive. It might
   also get cancelled by another command (we will see how this works). At that
   point, the command becomes inactive.

### Command construction and requirements

A command's constructor should accept parameters that it needs to execute. For
example, a `SpinShooter` command might accept a parameter that tells it a target
spin rate.

A command contains *requirements* which are a list of subsystems that the
command needs to operate. The rule in FRC programming is that only one command
should be using a subsystem at a time. This rule is enforced by specifying in a
command which subsystems it will require during execution.

If another command is triggered which uses a subsystem that an already-executing
command is using, then the new command is scheduled and the old command is
cancelled. Why do it this way? Because typically a new command is triggered
based on newer information (for example, imagine the user instructs the robot to
shoot, only to realize there is no game piece contained in the robot, the second
command to stow the shooter should take precedence).

Specifying required subsystems is optional, but very important to get right.
Command programming can be difficult to design, and you don't want two
conflicting commands telling the robot what to do. You may end up with strange
and hard to repeat behavior, or you may end up damaging the robot.

Requirements are added on construction of a command.

### initialize()

The initialize function of a command is executed right as the command is
triggered. It sets the stage for the execution of the command. Perhaps you want
to spin the shooter up to a certain speed, it might turn on the motor at full
acceleration, to get the motor spinning.

If there is any state that is needed during the life of the command, this is
where it should be initialized.

### execute()

The `execute` function is called once per event loop. It should do the work of
the command. In some cases, the command might not even need an `execute`
function. In the case of a `SpinShooter` command, we don't need to change the
motor acceleration, as it's already set to full.

### isFinished()

The `isFinished` function is called once per event loop to check if the command
has reached it's normal end condition. If `isFinished` returns true, then the
command is ended and becomes inactive.

Some commands always return true or false from `isFinished` depending on the
purpose.

### end(boolean interrupted)

The `end` function is called when a command has ended. If the command is ended
because `isFinished` return true, then the `interrupted` parameter is set to
false. If it's called because the command was cancelled, then `interrupted` is
true.

This function provides a chance to return things to a normal inactive state.

### Command pseudocode

You may think of the "execution" of a command like a `while` loop. The following
Java code resembles the way a command is executed. Keep in mind, the code isn't
exactly like this because it is split between many event loops.

```java
void commandIsTriggered() {
  initialize();
  while(!cancelled && !isFinished()) {
    execute();
  }
  end(cancelled);
}
```

## Binding commands to events

When we bind an input button to a command, we are telling the code to execute
the command when the event occurs.

Many types of events can be used. WPILib provides a lot of different ways to
handle them.

For example, if you want to execute a command when a button is pressed, and do
nothing when the button is released, you can use the `onTrue()` trigger of a
button to connect a command.

If you want to end the command when the button is released, you can use
`whileTrue` instead.

If you want to execute one command when it is pressed, and a different command
when it is false, then you can specify a command for both `onTrue` and
`onFalse`.

Every time you bind a trigger to a command, it returns the trigger so you can
add more bindings without repeating the code.

