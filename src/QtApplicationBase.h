#pragma once

template <class T> class QtApplicationBase: public T {

public:
  QtApplicationBase(int &argc, char **argv): T(argc, argv) {}

private:
  void init();
};

