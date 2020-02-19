# Simplekiq Gem Changes

### 4.0.1

- Add DD metric to keep track of worker group(ie: threaded, low_priority, common/undefined)

### 3.2.7

- Add rollkiq to gemspec

### 3.1.2

- Loosen the restriction on dogstatsd-ruby version

### 3.1.1

- Move hash.rb to extensions to make the require path less ambiguous

### 3.1.0

- Allow setting Sidekiq::Pro dogstatsd

### 3.0.1

- Fix issue with deep symolize keys where it did not work on arrays

### 3.0.0

- Remove slash from namespaced queue names

### 2.1.0

- Update simplekiq testing to allow perform_async to use symbolized keys
- Mute Sidekiq config from outputting on bootup

## 2.0.0

- Enforce singular hash params being sent in perform

### 1.3.0

- Revert 1.2.0

### 1.2.0

- Allow default queues for legacy jobs in rails projects

### 1.1.0

- Support queue priority

### 1.0.0

- Ensure that queues are not declared in config files
- Allow queue overrides

## 0.1.0

- Initial Release
