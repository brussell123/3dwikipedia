function h = PlotBB(bb,varargin)

h = plot([bb(1) bb(2) bb(2) bb(1) bb(1)],[bb(3) bb(3) bb(4) bb(4) bb(3)],varargin{:});
