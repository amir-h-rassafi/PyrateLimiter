BASELINE ?= /tmp/pyrate-master
CANDIDATE ?= /tmp/pyrate-candidate
REDIS_CPU ?= 0
BENCH_CPU ?= 2
ROUNDS ?= 5

.PHONY: benchmark-redis
benchmark-redis:
	@set -eu; \
	if [ "$$(uname -s)" != Linux ]; then \
		echo "This benchmark requires Linux (taskset and Docker CPU pinning)." >&2; exit 1; \
	fi; \
	for tool in docker taskset uv; do \
		command -v "$$tool" >/dev/null || { echo "Missing $$tool; install it before running this benchmark." >&2; exit 1; }; \
	done; \
	docker info >/dev/null 2>&1 || { echo "Docker is unavailable; start the Docker daemon and check your access." >&2; exit 1; }; \
	[ "$(REDIS_CPU)" != "$(BENCH_CPU)" ] || { echo "REDIS_CPU and BENCH_CPU must differ." >&2; exit 1; }; \
	taskset -c "$(REDIS_CPU)" true >/dev/null 2>&1 || { echo "REDIS_CPU=$(REDIS_CPU) is not available." >&2; exit 1; }; \
	taskset -c "$(BENCH_CPU)" true >/dev/null 2>&1 || { echo "BENCH_CPU=$(BENCH_CPU) is not available." >&2; exit 1; }; \
	redis_name=pyrate-bench-redis-$$$$; \
	trap 'docker stop "$$redis_name" >/dev/null 2>&1 || true' EXIT; \
	docker run -d --rm --name "$$redis_name" -p 127.0.0.1::6379 \
		--cpuset-cpus "$(REDIS_CPU)" --cpus 1 \
		--memory 512m --memory-swap 512m redis:7.2.4 >/dev/null; \
	attempt=0; \
	until docker exec "$$redis_name" redis-cli ping >/dev/null 2>&1; do \
		attempt=$$((attempt + 1)); \
		if [ "$$attempt" -ge 30 ]; then echo "Redis did not become ready:" >&2; docker logs "$$redis_name" >&2; exit 1; fi; \
		sleep 1; \
	done; \
	redis_port=$$(docker port "$$redis_name" 6379/tcp); redis_port=$${redis_port##*:}; \
	taskset -c "$(BENCH_CPU)" uv run --locked --group all python benchmarks/compare_redis_weighted_put.py \
		--baseline "$(BASELINE)" --candidate "$(CANDIDATE)" --rounds "$(ROUNDS)" \
		--redis-url "redis://127.0.0.1:$$redis_port"
