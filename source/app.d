import std.stdio;

import hellotriangle;
import blinkingredtriangle;
import gradienttriangle;
import gradientrectangle;
import upsidedowntriangle;
import invertedgradienttriangle;
import grayshadedtriangle;
import texturedrect;
import mixedtextures;
import animatedblending;
import kittenreflection;
import waterreflection;

void main()
{
    enum PROGRAM = "wr";
    try
    {
        switch (PROGRAM)
        {
            case "ht":
            {
                HelloTriangleApp app;
                app.run();
            }
            break;

            case "brt":
            {
                BlinkingRedTriangleApp app;
                app.run();
            }
            break;

            case "gt":
            {
                GradientTriangleApp app;
                app.run();
            }
            break;

            case "gr":
            {
                GradientRectangleApp app;
                app.run();
            }
            break;

            case "udt":
            {
                UpsideDownTriangleApp app;
                app.run();
            }
            break;

            case "igt":
            {
                InvertedGradientTriangleApp app;
                app.run();
            }
            break;

            case "gst":
            {
                GrayShadedTriangleApp app;
                app.run();
            }
            break;

            case "tr":
            {
                TexturedRectApp app;
                app.run();
            }
            break;

            case "mt":
            {
                MixedTexturesApp app;
                app.run();
            }
            break;

            case "ab":
            {
                AnimatedBlendingApp app;
                app.run();
            }
            break;

            case "kr":
            {
                KittenReflectionApp app;
                app.run();
            }
            break;

            case "wr":
            {
                WaterReflectionApp app;
                app.run();
            }
            break;

            default: assert(false);
        }
    }
    catch (Exception ex)
    {
        stderr.writeln(ex.msg);
    }
}
