BASELINE ?= /tmp/pyrate-master
CANDIDATE ?= /tmp/pyrate-candidate
REDIS_CPU ?= 0
BENCH_CPU ?= 2
ROUNDS ?= 5

.PHONY: benchmark-redis
benchmark-redis:
	docker run -d --rm --name pyrate-bench-redis -p 6379:6379 \
		--cpuset-cpus "$(REDIS_CPU)" --cpus 1 \
		--memory 512m --memory-swap 512m redis:7.2.4
	@trap 'docker stop pyrate-bench-redis >/dev/null' EXIT; \
		sleep 1; \
		taskset -c "$(BENCH_CPU)" uv run --group all python benchmarks/compare_redis_weighted_put.py \
		--baseline "$(BASELINE)" --candidate "$(CANDIDATE)" --rounds "$(ROUNDS)"
