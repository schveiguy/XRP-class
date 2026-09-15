import std.stdio;
import std.math;
import std.algorithm;
import raylib;

enum FPS = 60;

struct Vehicle
{
    enum tick = 1.0 / FPS;
    // limit to +/- 50 units/sec^2
    enum maxAccel = 50;
    // maximum speed in either direction
    enum maxSpeed = 100;
    enum drag = 1;

    double position = 0;
    double speed = 0;
    double accel = 0;

    void draw() {
        enum width = 50;
        enum height = 50;
        auto origin = Vector2((position - width/2), -height);
        DrawRectangleV(origin, Vector2(width, height), Colors.RED);
    }

    void accelerate(double a) {
        accel = max(-maxAccel, min(a, maxAccel));
    }

    void move() {
        double dragFactor = speed > 0 ? -drag : drag;
        // drag can't make vehicle go backwards.
        if(drag * tick > abs(speed))
            dragFactor = -speed / tick;
        double a = accel + dragFactor;
        //writeln(i"accel is $(accel), dragFactor is $(dragFactor), a is $(a), speed is $(speed)");
        position += speed * tick + 0.5 * a * tick * tick;
        speed += a * tick;
        speed = max(-maxSpeed, min(maxSpeed, speed));
    }
}

struct Target
{
    double position = 0;
    void draw() {
        enum radius = 25;
        auto origin = Vector2(position, -radius);
        DrawCircleV(origin, radius, Colors.BLACK);
        DrawCircleV(origin, radius * 2.0/3, Colors.WHITE);
        DrawCircleV(origin, radius * 1.0/3, Colors.RED);
    }
}

struct PID
{
    double p = 0;
    double i = 0;
    double d = 0;


    double lastErr = double.nan;
    double totalErr = 0;

    double calculate(double err)
    {
        if(i) {
            totalErr = totalErr + err / FPS;
            totalErr = max(-1/i, min(totalErr, 1/i));
        }
        auto dval = (err - lastErr) * FPS;
        if(isNaN(dval)) dval = 0;
        lastErr = err;
        return p * err + d * dval + i * totalErr;
    }
}

void main()
{
    InitWindow(800, 600, "The PID game!");
    SetTargetFPS(FPS);

    Target target;
    PID[] pid = [
        PID(p: 1, i: 0, d: 0),
        PID(p: 1, i: 0, d: 1),
        PID(p: 1, i: 0.01, d: 1),
    ];
    Vehicle[] vehicles = new Vehicle[pid.length];
    foreach(ref v; vehicles) v.position = -500;
    double a = 0;

    bool running = false;
    while(!WindowShouldClose())
    {
        BeginDrawing();
        ClearBackground(Colors.WHITE);

        if(IsKeyPressed(KeyboardKey.KEY_SPACE)) {
            running = !running;
        }
        // perform changes to speed.
        foreach(int i; 0 .. cast(int)pid.length) {
            auto ground = 600 - 100 - i * 150;
            DrawLine(0, ground, GetScreenWidth, ground, Colors.BLACK);
            auto err = target.position - vehicles[i].position;
            if(running)
            {
                vehicles[i].accelerate(pid[i].calculate(err));
                vehicles[i].move();
            }
            auto dist = abs(err);
            // determine the scale based on the target and the vehicle distance
            auto scale = (GetScreenWidth() / 2 - 100) / dist;
            if (scale > 1) scale = 1;
            // draw hash marks to show the scale
            int hashSize = 50 * cast(int)(1/scale);
            int hash = hashSize;
            while(GetScreenWidth() / 2 + hash * scale < GetScreenWidth())
            {
                auto center = Vector2(GetScreenWidth() / 2, ground);
                DrawLineV(center + Vector2(hash * scale, -5), center + Vector2(hash * scale, 5), Colors.BLACK);
                auto txt = TextFormat("%d", hash);
                DrawTextEx(GetFontDefault, txt, center + Vector2(cast(int)(hash * scale) - MeasureText(txt, 10)/2, 8), 10, 1, Colors.BLACK);
                DrawLineV(center - Vector2(hash * scale, -5), center - Vector2(hash * scale, 5), Colors.BLACK);
                txt = TextFormat("-%d", hash);
                DrawTextEx(GetFontDefault, txt, center + Vector2(cast(int)(-hash * scale) - MeasureText(txt, 10)/2, 8), 10, 1, Colors.BLACK);
                hash += hashSize;
            }
            // draw the distance
            auto txt = TextFormat("Distance: %0.1f", dist);
            DrawText(txt, (GetScreenWidth() - MeasureText("Distance: 000.0", 30)) / 2, ground + 20, 30, Colors.BLACK);
            DrawText(TextFormat("P: %g I: %g D: %g", pid[i].p, pid[i].i, pid[i].d), 10, ground + 20, 20, Colors.BLACK);

            rlPushMatrix();
            scope(exit) rlPopMatrix();
            rlTranslatef(GetScreenWidth() / 2, ground, 0);
            rlScalef(scale, scale, 0);
            target.draw();
            vehicles[i].draw();
        }
        EndDrawing();
    }
    CloseWindow();
}
