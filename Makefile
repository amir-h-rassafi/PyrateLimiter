BASELINE ?= /tmp/pyrate-master
CANDIDATE ?= /tmp/pyrate-candidate
REDIS_URL ?= redis://localhost:6379
BENCH_CPU ?= 2

.PHONY: benchmark-redis
benchmark-redis:
	taskset -c $(BENCH_CPU) uv run --group all python benchmarks/compare_redis_weighted_put.py \
		--baseline "$(BASELINE)" --candidate "$(CANDIDATE)" --redis-url "$(REDIS_URL)"
