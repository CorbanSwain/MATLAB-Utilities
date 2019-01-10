classdef ShapeBuilder < csmu.PlotBuilder
   properties
      Shape
   end
   
   properties (Constant)
      ShadowClass = 'matlab.graphics.primitive.Patch'
      ShadowClassTag = ''
      ShadowClassExcludeList = ''     
   end
   
   methods
      function plotGraphics(self, axisHandle)
         self.PlotHandle = plot(self.Shape, 'Parent', axisHandle);
         self.applyShadowClassProps;
      end
   end
end