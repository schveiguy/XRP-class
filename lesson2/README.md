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

If you look at the `DriveTrain` class in the XRP example code, you can see that
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

The constructor for the `DriveTrain` subsystem configures the motors, the
DifferentialDrive, and the IMU. All of the methods pertain to driving,
configuring, setting, and reading, the hardware components of the drive system.

### Arm subsystem

The `Arm` subsystem is even simpler. This subsystem contains a single
`XRPServo` object, and one interesting method, the `setAngle` method, which
tells the servo to go to a specific angle.

## RobotContainer

Recall in Java that the entry point for your program is `public static void
main`. However, in FRC robot code the framework is in charge of the start of the
program. Your code is initialized using your `RobotContainer` class.

The `RobotContainer` class should hold all your commands, subsystems, and
controllers. But before we 
