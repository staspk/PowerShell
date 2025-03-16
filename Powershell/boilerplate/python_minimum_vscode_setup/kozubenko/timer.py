import time

class Timer:
    start_time: float = None

    def start():
        Timer.start_time = time.perf_counter()

    def elapsed(timed_operation_title = ''):
        elapsed = (time.perf_counter() - Timer.start_time) * 1000                          #   converts elapsed from ns to ms
        if elapsed > 1000:                                                                 #   if elapsed more than 1 second:
            elapsed = elapsed / 1000                                                       #
            print(f'{timed_operation_title} Operation timed at: {elapsed:.3f}s')           #       convert and print in seconds, like: 1.234s 
        else:                                                                              #   else:
            print(f'{timed_operation_title} Operation timed at: {elapsed:.3f}ms')          #        print in ms, like:                 123.456ms or 0.000ms under 500ns

    def stop():
        elapsed = (time.perf_counter() - Timer.start_time) * 1000
        if elapsed > 1000:
            elapsed = elapsed / 1000
            print(f'Operation timed at: {elapsed:.3f}s')
        else:
            print(f'Operation timed at: {elapsed:.3f}ms')

        Timer.start_time = None