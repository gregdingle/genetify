library(CGIwithR)

graphDir = '/Users/greg/Desktop/genetify/graphs/'
graphURLroot = '/graphs/'


library(car)
data(Duncan)
attach(Duncan)
plot(education, prestige)

dev2bitmap(paste(graphDir, 'test.png', sep=''))